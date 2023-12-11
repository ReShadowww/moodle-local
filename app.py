from flask import Flask, Response, request
from flask_restful import Api, Resource
import mariadb
import sys

app = Flask(__name__)
api = Api(app)


def connect_to_maria_DB():
    try:
        conn = mariadb.connect(
            user="root",
            password="toor",
            host="127.0.0.1",
            port=3309,
            database="moodle_app",
        )
        conn.autocommit = True
        # print("CONNECTED TO DATABASE")
    except mariadb.Error as e:
        print(f"Error connecting to MariaDB Platform: {e}")
        sys.exit(1)
    return conn


def json_to_db(qu):

    list_of_keys = ["qtext", "answers", "user"]

    lst_of_counts = []
    if sorted(list(qu.keys())) == sorted(list_of_keys):
        # Get Cursor
        conn = connect_to_maria_DB()
        cur = conn.cursor()

        qtext = qu["qtext"]
        user = qu["user"]
        answers = qu["answers"]

        for answer in answers:
            try:

                # backwards compatibility
                if "type" not in answer.keys():
                    answer_type = None
                else:
                    answer_type = answer["type"]

                # Call procedure
                cur.callproc(
                    "u_q_a_c_t", (user, qtext, answer["answer"], answer["checked"], answer_type)
                )

                # What to execute
                statment = """
                SELECT sum(checked) FROM user_choice
                WHERE
                q_a_id = (SELECT id FROM question_answer WHERE a_id IN (SELECT id FROM answer WHERE a_text = %s) AND q_id IN (SELECT id FROM question WHERE q_text = %s))
                AND NOT user_id = (SELECT id FROM users WHERE user_name = %s);
                """
                data = (answer["answer"], qtext, user)

                # Execute
                cur.execute(statment, data)
                count = cur.fetchone()[0]
                count = int(count) if count else 0

                # Get data from DB
                a = {"answer": answer["answer"], "count": count}
                lst_of_counts.append(a)

            except mariadb.Error as e:
                print(f"Error: {e}")
        # print(lst_of_counts)
        conn.close()
    else:
        print("Provided key/keys were not found in allowed keys list !")
    return lst_of_counts


@app.after_request
def after_request(response):
    response.headers.set("Access-Control-Allow-Origin", "*")  # FIX SECURITY IMPORTANT !
    response.headers.set("Access-Control-Allow-Methods", "PUT")
    response.headers.set("Access-Control-Allow-Headers", "Content-Type")
    # print(response)
    return response


class super_duper_bum_bam_API(Resource):
    # POST REQUEST
    def post(self):
        args = request.json
        if type(args) == list:
            data = [json_to_db(q) for q in args]
        elif type(args) == dict:
            data = [json_to_db(args)]
        else:
            print(args, "<== ?????????????????????????????????????")
        return data


api.add_resource(super_duper_bum_bam_API, "/")


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5555)
