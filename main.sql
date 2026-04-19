CREATE TABLE Users (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

CREATE TABLE validation_rules (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    min_value INT,
    max_value INT,
    regex_pattern TEXT
);

CREATE TABLE validated_data (
    id INT PRIMARY KEY,
    user_id INT NOT NULL,
    validation_rule_id INT NOT NULL,
    data TEXT NOT NULL,
    is_valid BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES Users(id),
    FOREIGN KEY (validation_rule_id) REFERENCES validation_rules(id)
);

INSERT INTO validation_rules (id, name, type, min_value, max_value, regex_pattern)
VALUES
(1, 'Email', 'email', NULL, NULL, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
(2, 'Password', 'password', 8, 32, '^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*_=+-]).{8,32}$'),
(3, 'Name', 'string', NULL, NULL, '^[a-zA-Z ]+$');

CREATE FUNCTION validate_data(p_user_id INT, p_validation_rule_id INT, p_data TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_valid BOOLEAN;
    v_min_value INT;
    v_max_value INT;
    v_regex_pattern TEXT;
BEGIN
    SELECT is_valid INTO v_is_valid FROM validated_data WHERE user_id = p_user_id AND validation_rule_id = p_validation_rule_id;
    IF v_is_valid THEN
        RETURN TRUE;
    END IF;

    SELECT min_value, max_value, regex_pattern INTO v_min_value, v_max_value, v_regex_pattern FROM validation_rules WHERE id = p_validation_rule_id;

    IF v_min_value IS NOT NULL AND v_max_value IS NOT NULL THEN
        IF LENGTH(p_data) >= v_min_value AND LENGTH(p_data) <= v_max_value THEN
            IF v_regex_pattern IS NOT NULL THEN
                IF p_data ~ v_regex_pattern THEN
                    INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, TRUE);
                    RETURN TRUE;
                ELSE
                    INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, FALSE);
                    RETURN FALSE;
                END IF;
            ELSE
                INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, TRUE);
                RETURN TRUE;
            END IF;
        ELSE
            INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, FALSE);
            RETURN FALSE;
        END IF;
    ELSE
        IF v_regex_pattern IS NOT NULL THEN
            IF p_data ~ v_regex_pattern THEN
                INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, TRUE);
                RETURN TRUE;
            ELSE
                INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, FALSE);
                RETURN FALSE;
            END IF;
        ELSE
            INSERT INTO validated_data (user_id, validation_rule_id, data, is_valid) VALUES (p_user_id, p_validation_rule_id, p_data, TRUE);
            RETURN TRUE;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION validate_user(p_user_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_valid BOOLEAN;
BEGIN
    SELECT is_valid INTO v_is_valid FROM validated_data WHERE user_id = p_user_id;
    IF v_is_valid THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT validate_data(1, 1, 'test@example.com');
SELECT validate_data(1, 2, 'TestPassword123!');
SELECT validate_data(1, 3, 'Test Name');
SELECT validate_user(1);