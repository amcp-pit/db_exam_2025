-- Table user
CREATE TABLE IF NOT EXISTS public.user (
    user_id INT NOT NULL PRIMARY KEY,
    username VARCHAR(128) NOT NULL
);


-- Table model
CREATE TABLE IF NOT EXISTS public.model (
    model_id INT NOT NULL PRIMARY KEY,
    creator_id INT NOT NULL,
    last_editor_id INT NOT NULL,
    last_update_time TIMESTAMP NOT NULL,

    FOREIGN KEY (creator_id) REFERENCES "user"(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (last_editor_id) REFERENCES "user"(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);


-- Table access_list
CREATE TABLE IF NOT EXISTS public.access_list (
    user_id INT NOT NULL,
    model_id INT NOT NULL,
    read_permission BOOLEAN,
    write_permission BOOLEAN,

    PRIMARY KEY (user_id, model_id),
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (model_id) REFERENCES model(model_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table plane
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

    vector1 INT NULL,
    vector2 INT NULL,

    FOREIGN KEY (model_id) REFERENCES model(model_id) ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT chk_vectors_normalized CHECK (
        (ABS(vector1_x * vector1_x + vector1_y * vector1_y + vector1_z * vector1_z - 1) < 1e-6) AND
        (ABS(vector2_x * vector2_x + vector2_y * vector2_y + vector2_z * vector2_z - 1) < 1e-6)
    ),
    CONSTRAINT chk_vectors_orthogonal CHECK (
        ABS(vector1_x * vector2_x + vector1_y * vector2_y + vector1_z * vector2_z) < 1e-6
    )
);


-- Table sketch
CREATE TABLE IF NOT EXISTS public.sketch (
    sketch_id INT NOT NULL PRIMARY KEY,
    plane_id INT NOT NULL,

    FOREIGN KEY (plane_id) REFERENCES plane(plane_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table entity
CREATE TABLE IF NOT EXISTS public.entity (
    entity_id INT NOT NULL PRIMARY KEY,
    sketch_id INT NOT NULL,

    FOREIGN KEY (sketch_id) REFERENCES sketch(sketch_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table param
CREATE TABLE IF NOT EXISTS public.param  (
    param_id INT NOT NULL PRIMARY KEY,
    value  DOUBLE PRECISION NOT NULL
);


-- Table object_type 
CREATE TABLE IF NOT EXISTS public.object_type (
    object_type_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    free_degree INT NOT NULL
);


-- Table object
CREATE TABLE IF NOT EXISTS public.object  (
    object_id INT NOT NULL PRIMARY KEY,
    object_type_id INT NOT NULL,
    parent_id INT,
    num INT,

    FOREIGN KEY (object_type_id) REFERENCES object_type(object_type_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (object_id) REFERENCES entity(entity_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES "object"(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table object_param
CREATE TABLE IF NOT EXISTS public.object_param  (
    object_id INT NOT NULL,
    param_id INT NOT NULL,
    num INT NULL,

    PRIMARY KEY (object_id, param_id),
    FOREIGN KEY (param_id) REFERENCES "param"(param_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (object_id) REFERENCES "object"(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table constraint_type
CREATE TABLE IF NOT EXISTS public.constraint_type  (
    constraint_type_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    is_parametric BOOLEAN NOT NULL
);


-- Table constraint
CREATE TABLE IF NOT EXISTS public.constraint (
    constraint_id INT NOT NULL PRIMARY KEY,
    constraint_type_id INT NOT NULL,

    FOREIGN KEY (constraint_type_id) REFERENCES constraint_type(constraint_type_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (constraint_id) REFERENCES entity(entity_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table constraint_info
CREATE TABLE IF NOT EXISTS public.constraint_info (
    constraint_id INT NOT NULL,
    object_id  INT NOT NULL,

    PRIMARY KEY (constraint_id, object_id),
    FOREIGN KEY (constraint_id) REFERENCES "constraint"(constraint_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (object_id) REFERENCES "object"(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table constraint_param 
CREATE TABLE IF NOT EXISTS public.constraint_param  (
    constraint_id INT NOT NULL,
    param_id INT NOT NULL,

    PRIMARY KEY (constraint_id, param_id),
    FOREIGN KEY (constraint_id) REFERENCES "constraint"(constraint_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (param_id) REFERENCES "param"(param_id) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE public.plane ADD CONSTRAINT fk_plane_object_point FOREIGN KEY (point_id) REFERENCES object(object_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE public.plane ADD CONSTRAINT fk_plane_object_vector_1 FOREIGN KEY (vector1) REFERENCES object(object_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE public.plane ADD CONSTRAINT fk_plane_object_vector_2 FOREIGN KEY (vector2) REFERENCES object(object_id) ON DELETE CASCADE ON UPDATE CASCADE;

INSERT INTO "object_type" ("object_type_id", "name", "free_degree") VALUES 
(1, 'Point', 2),
(2, 'Segment', 4),
(3, 'Circle', 3),
(4, 'Arc', 5);

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

CREATE OR REPLACE FUNCTION handle_segment_deletion()
RETURNS TRIGGER AS $$
DECLARE
    related_plane RECORD;
    other_vector INT;
BEGIN
    RAISE NOTICE 'Удаляем сегмент с object_id: %', OLD.object_id;

    -- Проверяем, что удаляемый объект - сегмент
    IF (SELECT object_type_id FROM object WHERE object_id = OLD.object_id) = 2 THEN
        -- Ищем связанную плоскость
        SELECT * INTO related_plane
        FROM plane
        WHERE vector1 = OLD.object_id OR vector2 = OLD.object_id;

        RAISE NOTICE 'Нашли связанную плоскость с plane_id: %', related_plane.plane_id;

        -- Если плоскость найдена
        IF FOUND THEN
            -- Определяем второй вектор (vector1 или vector2)
            IF related_plane.vector1 = OLD.object_id THEN
                other_vector := related_plane.vector2;
            ELSE
                other_vector := related_plane.vector1;
            END IF;

            RAISE NOTICE 'Нашли второй вектор с id: %', other_vector;

            -- Обнуляем информацию о векторах в плоскости
            UPDATE plane
            SET vector1 = NULL, vector2 = NULL
            WHERE plane_id = related_plane.plane_id;

            -- Удаляем второй вектор
            DELETE FROM object WHERE object_id = other_vector;
        END IF;
    END IF;

    RAISE NOTICE 'Удаляем исходный объект с object_id: %', OLD.object_id;

    -- Удаляем сам объект
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_object_delete
BEFORE DELETE ON object
FOR EACH ROW
EXECUTE FUNCTION handle_segment_deletion();
