-- Создание таблицы user
CREATE TABLE IF NOT EXISTS public.user (
    user_id INT NOT NULL PRIMARY KEY,
    username VARCHAR(128) NOT NULL
);

-- Создание таблицы model
CREATE TABLE IF NOT EXISTS public.model (
    model_id INT NOT NULL PRIMARY KEY,
    creator_id INT NOT NULL,
    last_editor_id INT NOT NULL,
    last_update_time TIMESTAMP NOT NULL,
    CONSTRAINT fk_creator FOREIGN KEY (creator_id) REFERENCES "user"(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_last_editor FOREIGN KEY (last_editor_id) REFERENCES "user"(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Создание таблицы access_list
CREATE TABLE IF NOT EXISTS public.access_list (
    user_id INT NOT NULL,
    model_id INT NOT NULL,
    read_permission BOOLEAN,
    write_permission BOOLEAN,
    PRIMARY KEY (user_id, model_id),
    CONSTRAINT fk_access_user FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_access_model FOREIGN KEY (model_id) REFERENCES model(model_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы plane
CREATE TABLE IF NOT EXISTS public.plane (
    plane_id INT NOT NULL PRIMARY KEY,
    model_id INT NOT NULL,
    point_id INT NULL,

    vector1_x DOUBLE PRECISION NOT NULL,
    vector1_y DOUBLE PRECISION NOT NULL,
    vector1_z DOUBLE PRECISION NOT NULL,

    vector2_x DOUBLE PRECISION NOT NULL,
    vector2_y DOUBLE PRECISION NOT NULL,
    vector2_z DOUBLE PRECISION NOT NULL,

    FOREIGN KEY (model_id) REFERENCES model(model_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_vectors_normalized CHECK (
        (vector1_x * vector1_x + vector1_y * vector1_y + vector1_z * vector1_z = 1) AND
        (vector2_x * vector2_x + vector2_y * vector2_y + vector2_z * vector2_z = 1)
    ),
    CONSTRAINT chk_vectors_orthogonal CHECK (
        (vector1_x * vector2_x + vector1_y * vector2_y + vector1_z * vector2_z = 0)
    )
);


-- Создание таблицы sketch
CREATE TABLE IF NOT EXISTS public.sketch (
    sketch_id INT NOT NULL PRIMARY KEY,
    plane_id INT NOT NULL,
    CONSTRAINT fk_sketch_plane FOREIGN KEY (plane_id) REFERENCES plane(plane_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы entity
CREATE TABLE IF NOT EXISTS public.entity (
    entity_id INT NOT NULL PRIMARY KEY,
    sketch_id INT NOT NULL,
    CONSTRAINT fk_entity_sketch FOREIGN KEY (sketch_id) REFERENCES sketch(sketch_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы param
CREATE TABLE IF NOT EXISTS public.param (
    param_id INT NOT NULL PRIMARY KEY,
    value DOUBLE PRECISION NOT NULL
);

-- Создание таблицы object_type
CREATE TABLE IF NOT EXISTS public.object_type (
    object_type_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    free_degree INT NOT NULL
);

-- Создание таблицы object
CREATE TABLE IF NOT EXISTS public.object (
    object_id INT NOT NULL PRIMARY KEY,
    object_type_id INT NOT NULL,
    parent_id INT,
    num INT,
    CONSTRAINT fk_object_type FOREIGN KEY (object_type_id) REFERENCES object_type(object_type_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_object_entity FOREIGN KEY (object_id) REFERENCES entity(entity_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_object_parent FOREIGN KEY (parent_id) REFERENCES "object"(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы object_param
CREATE TABLE IF NOT EXISTS public.object_param (
    object_id INT NOT NULL,
    param_id INT NOT NULL,
    num INT NULL,
    PRIMARY KEY (object_id, param_id),
    CONSTRAINT fk_object_param_param FOREIGN KEY (param_id) REFERENCES "param"(param_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_object_param_object FOREIGN KEY (object_id) REFERENCES "object"(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы constraint_type
CREATE TABLE IF NOT EXISTS public.constraint_type (
    constraint_type_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    is_parametric BOOLEAN NOT NULL
);

-- Создание таблицы constraint
CREATE TABLE IF NOT EXISTS public.constraint (
    constraint_id INT NOT NULL PRIMARY KEY,
    constraint_type_id INT NOT NULL,
    CONSTRAINT fk_constraint_type FOREIGN KEY (constraint_type_id) REFERENCES constraint_type(constraint_type_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_constraint_entity FOREIGN KEY (constraint_id) REFERENCES entity(entity_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы constraint_info
CREATE TABLE IF NOT EXISTS public.constraint_info (
    constraint_id INT NOT NULL,
    object_id INT NOT NULL,
    PRIMARY KEY (constraint_id, object_id),
    CONSTRAINT fk_constraint_info_constraint FOREIGN KEY (constraint_id) REFERENCES "constraint"(constraint_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_constraint_info_object FOREIGN KEY (object_id) REFERENCES "object"(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Создание таблицы constraint_param
CREATE TABLE IF NOT EXISTS public.constraint_param (
    constraint_id INT NOT NULL,
    param_id INT NOT NULL,
    PRIMARY KEY (constraint_id, param_id),
    CONSTRAINT fk_constraint_param_constraint FOREIGN KEY (constraint_id) REFERENCES "constraint"(constraint_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_constraint_param_param FOREIGN KEY (param_id) REFERENCES "param"(param_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION handle_plane_basis_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, если объект связан с плоскостью через point_id
    IF (SELECT COUNT(*) FROM plane WHERE point_id = OLD.object_id) > 0 THEN
        -- Устанавливаем point_id в NULL для всех объектов, связанных с этим point_id
        UPDATE plane
        SET point_id = NULL
        WHERE point_id = OLD.object_id;

        -- Проверяем, если после удаления объекта point_id больше не используется
        IF (SELECT COUNT(*) FROM plane WHERE point_id = OLD.object_id) = 0 THEN
            -- Если point_id больше не используется, удаляем все отрезки (если такие есть)
            DELETE FROM object 
            WHERE object_id IN (
                SELECT object_id FROM object
                WHERE object_type_id = 2  -- Тип 'Segment'
                AND object_id <> OLD.object_id  -- Исключаем объект, который уже удален
                AND EXISTS (
                    SELECT 1 FROM plane WHERE point_id = OLD.object_id
                )
            );
        END IF;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- Создание триггера для удаления объектов
CREATE TRIGGER before_object_delete
BEFORE DELETE ON object
FOR EACH ROW
EXECUTE FUNCTION handle_plane_basis_deletion();

-- Вставка данных в object_type
INSERT INTO "object_type" ("object_type_id", "name", "free_degree") VALUES 
(1, 'Point', 2),
(2, 'Segment', 4),
(3, 'Circle', 3),
(4, 'Arc', 5);

SELECT * FROM object_type;

-- Вставка данных в constraint_type
INSERT INTO "constraint_type" ("constraint_type_id", "name", "is_parametric") VALUES 
(0, 'Fixed', false),
(1, 'Equal', false),
(2, 'Vertical', false),
(3, 'Horizontal', false),
(4, 'Parallel', false),
(5, 'Ortho', false),
(6, 'Tangent', false),
(7, 'Coincident', false),
(8, 'Midpoint', false),
(9, 'Collinear', false),
(10, 'Symmetric', false),
(11, 'Concentric', false),
(12, 'Arcbase', false),
(13, 'Distance', true),
(14, 'Angle', true),
(15, 'Dimension', true);

SELECT * FROM constraint_type;
--
---- Вставка пользователей
--INSERT INTO "user" (user_id, username) VALUES (1, 'user1'), (2, 'user2');
--
---- Вставка моделей
--INSERT INTO "model" (model_id, creator_id, last_editor_id, last_update_time) 
--VALUES (1, 1, 2, CURRENT_TIMESTAMP);
--
---- Вставка объектов типов
--INSERT INTO "object_type" ("object_type_id", "name", "free_degree") 
--VALUES (1, 'Point', 2), (2, 'Segment', 4), (3, 'Circle', 3), (4, 'Arc', 5);
--SELECT * FROM "object_type";
--
---- Вставка ограничений
--INSERT INTO "constraint_type" ("constraint_type_id", "name", "is_parametric") 
--VALUES (0, 'Fixed', false), (1, 'Equal', false), (2, 'Vertical', false);
--SELECT * FROM "constraint_type";
---- Вставка плоскостей
--INSERT INTO "plane" (plane_id, model_id, point_id, vector1_x, vector1_y, vector1_z, vector2_x, vector2_y, vector2_z) 
--VALUES (1, 1, NULL, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
--SELECT * FROM "plane";
--
---- Вставка объектов
--INSERT INTO "object" (object_id, object_type_id, parent_id, num) 
--VALUES (1, 1, NULL, 1), (2, 2, 1, 1);  -- Пример объекта 'Point' и связанного с ним 'Segment'
--SELECT * FROM "object";
---- Удаление первого отрезка
--DELETE FROM "object" WHERE object_id = 1;
---- Проверка, что информация о базисе плоскости не была удалена
--SELECT * FROM "plane";
---- Проверка, что второй отрезок был удален
--SELECT * FROM "object";
--
--
--
---- Вставка ограничений для объектов
--INSERT INTO "constraint" (constraint_id, constraint_type_id) 
--VALUES (1, 0);  -- Связываем ограничения с объектами
--
--
---- Проверка корректности данных
--SELECT * FROM object_type;
--SELECT * FROM constraint_type;
--SELECT * FROM plane;
--SELECT * FROM object;
