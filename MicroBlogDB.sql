-- Project: MicroBlogDB
-- A simplified Twitter-like microblogging platform database
-- DBMS: MySQL

-- 1) Create the database
DROP DATABASE IF EXISTS MicroBlogDB;
CREATE DATABASE MicroBlogDB;
USE MicroBlogDB;

-- 2) Create tables with relationships (foreign keys)
-- Users table: stores sensitive login data (email and password)
CREATE TABLE Users (
    user_id     INT AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    BINARY(64)   NOT NULL,
    created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- Profiles table: 1-to-1 relationship with Users
CREATE TABLE Profiles (
    profile_id  INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL UNIQUE,
    username    VARCHAR(50) NOT NULL UNIQUE,
    bio         VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);


CREATE TABLE Tweets (
    tweet_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    content     VARCHAR(280) NOT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Follows table: self-referencing many-to-many relationship between users
CREATE TABLE Follows (
    follower_id  INT NOT NULL,
    followed_id  INT NOT NULL,
    followed_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    FOREIGN KEY (follower_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (followed_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Likes table: many-to-many relationship between Users and Tweets
CREATE TABLE Likes (
    user_id     INT NOT NULL,
    tweet_id    INT NOT NULL,
    liked_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, tweet_id),
    FOREIGN KEY (user_id)  REFERENCES Users(user_id)   ON DELETE CASCADE,
    FOREIGN KEY (tweet_id) REFERENCES Tweets(tweet_id) ON DELETE CASCADE
);

-- 3) Procedure: createAccount
--    Creates a new user account and its profile in one call
DELIMITER $$

CREATE PROCEDURE createAccount(
    IN p_email    VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_username VARCHAR(50),
    IN p_bio      VARCHAR(255)
)
BEGIN
    DECLARE new_user_id INT;

    -- Insert the user with the password hashed using MD5
    INSERT INTO Users (email, password)
    VALUES (p_email, UNHEX(MD5(p_password)));

    SET new_user_id = LAST_INSERT_ID();

    -- Insert the profile linked to the same user
    INSERT INTO Profiles (user_id, username, bio)
    VALUES (new_user_id, p_username, p_bio);
END$$

DELIMITER ;

-- 4) Procedure: User_Follow
--    Takes the follower's username and the target username
DELIMITER $$

CREATE PROCEDURE User_Follow(
    IN p_follower_username VARCHAR(50),
    IN p_followed_username VARCHAR(50)
)
BEGIN
    DECLARE v_follower_id INT;
    DECLARE v_followed_id INT;

    SELECT user_id INTO v_follower_id FROM Profiles WHERE username = p_follower_username;
    SELECT user_id INTO v_followed_id FROM Profiles WHERE username = p_followed_username;

    INSERT INTO Follows (follower_id, followed_id)
    VALUES (v_follower_id, v_followed_id);
END$$

DELIMITER ;

-- 5) Populate tables with sample data
-- Create accounts via the procedure (creates user + profile together)
CALL createAccount('sara@example.com',  'Sara@123',   'sara_dev',   'Developer and tech enthusiast');
CALL createAccount('khalid@example.com','Khalid@123', 'khalid_k',   'Graphic designer');
CALL createAccount('nora@example.com',  'Nora@123',   'nora_writes','Content writer');
CALL createAccount('omar@example.com',  'Omar@123',   'omar_gamer', 'Video game enthusiast');

-- Add tweets
INSERT INTO Tweets (user_id, content) VALUES
(1, 'My first tweet on this platform!'),
(1, 'Learning SQL today and it is really fun'),
(2, 'Designed a new logo today'),
(3, 'A new article about creative writing coming soon'),
(4, 'Who wants to play tonight?');

-- Follows using the procedure
CALL User_Follow('khalid_k', 'sara_dev');
CALL User_Follow('nora_writes', 'sara_dev');
CALL User_Follow('omar_gamer', 'khalid_k');
CALL User_Follow('sara_dev', 'nora_writes');

-- Likes
INSERT INTO Likes (user_id, tweet_id) VALUES
(2, 1),
(3, 1),
(4, 2),
(1, 3);

-- 6) Display the data
SELECT * FROM Users;
SELECT * FROM Profiles;
SELECT * FROM Tweets;
SELECT * FROM Follows;
SELECT * FROM Likes;

-- 7) Tweet count for a single user (example: sara_dev)
SELECT p.username, COUNT(t.tweet_id) AS tweet_count
FROM Profiles p
JOIN Tweets t ON p.user_id = t.user_id
WHERE p.username = 'sara_dev'
GROUP BY p.username;