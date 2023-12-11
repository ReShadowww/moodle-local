DROP DATABASE if EXISTS mooodle_app;
CREATE DATABASE moodle_app;

create table moodle_app.question(
    id int auto_increment primary key,
    q_text TEXT not null
);

create table moodle_app.answer(
    id int auto_increment primary key,
    a_text TEXT NOT NULL,
    a_type TEXT
);

CREATE TABLE moodle_app.question_answer(
	 id int AUTO_INCREMENT,
    a_id int not null,
    q_id int not null,
    primary key(id, a_id, q_id),
	 CONSTRAINT fk_qa_answer foreign key (a_id) references answer (id),
    CONSTRAINT fk_qa_question foreign key (q_id) references question (id)
);

create table moodle_app.users(
    id int auto_increment primary key,
    user_name TEXT NOT NULL
);

create table moodle_app.user_choice(
   id int auto_increment primary key,
   user_id int NOT NULL,
   q_a_id INT NOT NULL,
   checked TINYINT(1) NOT NULL,
   CONSTRAINT fk_user_id foreign key (user_id) references users (id),
   CONSTRAINT fk_q_a_id foreign key (q_a_id) references question_answer (id)
);

DELIMITER $$
USE moodle_app $$
CREATE PROCEDURE
u_q_a_c_t ( IN my_user TEXT, IN my_question TEXT, IN my_answer TEXT, IN my_checked TINYINT(1), IN my_type TEXT )
BEGIN
	
	SET @user_user = my_user;
	SET @qu_text = my_question;
	SET @an_text = my_answer;
	SET @an_checked = my_checked;
	SET @an_type = my_type;
	
	SET @user_id = NULL;
	SET @qu_id = NULL;
	SET @an_id = NULL;
	SET @q_a_id = NULL;
	
	# INSERT USER IF NEW
	SELECT @user_id:=id FROM users WHERE user_name = @user_user;
	IF @user_id IS NULL
   THEN
     INSERT INTO users(user_name) VALUES (@user_user);
     SELECT @user_id := LAST_INSERT_ID();
   END IF;
	
	# INSERT QUESTION
	SELECT @qu_id:=id FROM question WHERE q_text = @qu_text;
   IF @qu_id IS NULL
   THEN
     INSERT INTO question(q_text) VALUES (@qu_text);
     SELECT @qu_id := LAST_INSERT_ID();
   END IF;

   # INSER ANSWERS
   SELECT @an_id:=id FROM answer WHERE a_text = @an_text AND id IN (SELECT a_id FROM question_answer WHERE q_id = @qu_id);
   IF @an_id IS NULL
   THEN
     INSERT INTO answer(a_text, a_type) VALUES (@an_text, @an_type);
     SELECT @an_id := LAST_INSERT_ID();
   END IF;
   
	# MATCH ANSWERS WITH QUESTION
	SELECT @q_a_id:=id FROM question_answer WHERE a_id = @an_id AND q_id = @qu_id;
   IF @q_a_id IS NULL
   THEN
	   INSERT INTO question_answer(a_id, q_id) VALUES (@an_id, @qu_id);
	   SELECT @q_a_id := LAST_INSERT_ID();
	END IF;
   
   # INSERT USER CHECKED
	IF NOT exists(SELECT id FROM user_choice WHERE user_id = @user_id AND q_a_id = @q_a_id)
   THEN
	   INSERT INTO user_choice(user_id, q_a_id, checked) VALUES (@user_id, @q_a_id, @an_checked);
	ELSE
		UPDATE user_choice SET checked = @an_checked WHERE user_id = @user_id AND q_a_id = @q_a_id;
	END IF;
   
   SELECT sum(checked), q_a_id FROM user_choice WHERE q_a_id = @q_a_id;
END $$