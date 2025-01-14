CREATE TABLE IF NOT EXISTS public.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.models (
    model_id SERIAL PRIMARY KEY,
    creator_id INT NOT NULL,
    last_editor_id INT NOT NULL,
    last_update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_creator FOREIGN KEY (creator_id) REFERENCES public.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_last_editor FOREIGN KEY (last_editor_id) REFERENCES public.users(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS public.access_permissions (
    user_id INT NOT NULL,
    model_id INT NOT NULL,
    can_read BOOLEAN DEFAULT FALSE,
    can_write BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, model_id),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_model FOREIGN KEY (model_id) REFERENCES public.models(model_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.planes (
    plane_id SERIAL PRIMARY KEY,
    model_id INT NOT NULL,
    point_reference INT NULL,
    vector1_x DOUBLE PRECISION NOT NULL,
    vector1_y DOUBLE PRECISION NOT NULL,
    vector1_z DOUBLE PRECISION NOT NULL,
    vector2_x DOUBLE PRECISION NOT NULL,
    vector2_y DOUBLE PRECISION NOT NULL,
    vector2_z DOUBLE PRECISION NOT NULL,
    CONSTRAINT fk_plane_model FOREIGN KEY (model_id) REFERENCES public.models(model_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.sketches (
    sketch_id SERIAL PRIMARY KEY,
    plane_id INT NOT NULL,
    CONSTRAINT fk_sketch_plane FOREIGN KEY (plane_id) REFERENCES public.planes(plane_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.primitives (
    primitive_id SERIAL PRIMARY KEY,
    sketch_id INT NOT NULL,
    CONSTRAINT fk_primitive_sketch FOREIGN KEY (sketch_id) REFERENCES public.sketches(sketch_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.parameters (
    parameter_id SERIAL PRIMARY KEY,
    value DOUBLE PRECISION NOT NULL CHECK(value > 0)
);

CREATE TABLE IF NOT EXISTS public.object_types (
    object_type_id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    degrees_of_freedom INT NOT NULL CHECK(degrees_of_freedom >= 0)
);

CREATE TABLE IF NOT EXISTS public.objects (
    object_id SERIAL PRIMARY KEY,
    object_type_id INT NOT NULL,
    parent_object_id INT,
    order_num INT,
    CONSTRAINT fk_object_type FOREIGN KEY (object_type_id) REFERENCES public.object_types(object_type_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_object_primitive FOREIGN KEY (object_id) REFERENCES public.primitives(primitive_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_parent_object FOREIGN KEY (parent_object_id) REFERENCES public.objects(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.object_parameters (
    object_id INT NOT NULL,
    parameter_id INT NOT NULL,
    order_num INT NULL,
    PRIMARY KEY (object_id, parameter_id),
    CONSTRAINT fk_object_parameter_param FOREIGN KEY (parameter_id) REFERENCES public.parameters(parameter_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_object_parameter_object FOREIGN KEY (object_id) REFERENCES public.objects(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.constraint_types (
    constraint_type_id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    is_parametric BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS public.constraints (
    constraint_id SERIAL PRIMARY KEY,
    constraint_type_id INT NOT NULL,
    CONSTRAINT fk_constraint_type FOREIGN KEY (constraint_type_id) REFERENCES public.constraint_types(constraint_type_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT fk_constraint_primitive FOREIGN KEY (constraint_id) REFERENCES public.primitives(primitive_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.constraint_info (
    constraint_id INT NOT NULL,
    object_id INT NOT NULL,
    PRIMARY KEY (constraint_id, object_id),
    CONSTRAINT fk_constraint_info_constraint FOREIGN KEY (constraint_id) REFERENCES public.constraints(constraint_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_constraint_info_object FOREIGN KEY (object_id) REFERENCES public.objects(object_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS public.constraint_parameters (
    constraint_id INT NOT NULL,
    parameter_id INT NOT NULL,
    PRIMARY KEY (constraint_id, parameter_id),
    CONSTRAINT fk_constraint_param_constraint FOREIGN KEY (constraint_id) REFERENCES public.constraints(constraint_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_constraint_param_param FOREIGN KEY (parameter_id) REFERENCES public.parameters(parameter_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION handle_plane_basis_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM planes WHERE point_reference = OLD.object_id) THEN
        UPDATE planes SET point_reference = NULL WHERE point_reference = OLD.object_id;

        IF NOT EXISTS (SELECT 1 FROM planes WHERE point_reference = OLD.object_id) THEN
            DELETE FROM objects WHERE object_type_id = 2 AND object_id <> OLD.object_id;
        END IF;
    END IF;

    RETURN OLD;
    END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER before_object_delete
BEFORE DELETE ON objects
FOR EACH ROW
EXECUTE FUNCTION handle_plane_basis_deletion();

INSERT INTO "object_types" ("object_type.id", "name", "degrees_of_freedom") VALUES
(1, 'Point', 2),
(2, 'Segment', 4),
(3, 'Circle', 3),
(4, 'Arc', 5);
ON CONFLICT (name) DO NOTHING;

INSERT INTO "constraint_types" ("constraint_type.id", "name", "is_parametric") VALUES
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
ON CONFLICT (name) DO NOTHING;

INSERT INTO "users" (username) VALUES ('user1'), ('user2');

INSERT INTO "models" (creator.id , last_editor.id , last_update_time)
VALUES (1 , 1 , CURRENT_TIMESTAMP);
