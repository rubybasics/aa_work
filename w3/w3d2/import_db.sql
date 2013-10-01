CREATE TABLE users (

  id INTEGER PRIMARY KEY,

  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
	id INTEGER PRIMARY KEY,

	title VARCHAR(255) NOT NULL,
	body VARCHAR(255) NOT NULL,

	FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
	id INTEGER PRIMARY KEY,

	FOREIGN KEY (question_id) REFERENCES questions(id),
	FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
	id INTEGER PRIMARY KEY,

	parent_reply_id INTEGER,
	FOREIGN KEY (question_id) REFERENCES questions(id),
	FOREIGN KEY (user_id) REFERENCES users(id)

);

CREATE TABLE question_likes (
	id INTEGER PRIMARY KEY,

	FOREIGN KEY (question_id) REFERENCES questions(id),
	FOREIGN KEY (user_id) REFERENCES users(id)
);