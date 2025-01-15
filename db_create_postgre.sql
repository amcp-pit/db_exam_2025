CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL
);

CREATE TABLE models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    creator_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_updator_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE access_lists (
    id SERIAL PRIMARY KEY,
    model_id INT NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read BOOLEAN,
    edit BOOLEAN
);

CREATE TABLE objects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    free_degrees INT NOT NULL CHECK (free_degrees >= 0)
);

CREATE TABLE entities (
    id SERIAL PRIMARY KEY,
    object_id INT NOT NULL REFERENCES objects(id) ON DELETE CASCADE
);

CREATE TABLE params (
    id SERIAL PRIMARY KEY,
    entity_id INT NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    name VARCHAR(10),
    value FLOAT NOT NULL CHECK (value >= 0)
);


CREATE TABLE constraint_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(15) NOT NULL
);

CREATE TABLE constraints (
    id SERIAL PRIMARY KEY,
    constraint_type_id INT NOT NULL REFERENCES constraint_types(id) ON DELETE CASCADE,
    fitst_entity_id INT NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    second_entity_id INT REFERENCES entities(id) ON DELETE CASCADE, 
    value FLOAT
);

CREATE TABLE sketches (
    id SERIAL PRIMARY KEY,
    model_id INT NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    entity_id INT NOT NULL REFERENCES entities(id) ON DELETE CASCADE
);

CREATE TABLE entity_sketch_relations (
    id SERIAL PRIMARY KEY,
    entity_id INT NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    sketch_id INT NOT NULL REFERENCES sketches(id) ON DELETE CASCADE,
    CONSTRAINT entity_sketch_relation_uniq UNIQUE (entity_id, sketch_id)
);
