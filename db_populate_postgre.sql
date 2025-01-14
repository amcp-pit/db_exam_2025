-- ADD USERS, THEIR MODELS AND ACCESSES

INSERT INTO users (id, username) VALUES 
(1, 'user1'), 
(2, 'user2'), 
(3, 'user3');

INSERT INTO models (id, name, creator_id, last_updator_id) VALUES 
(1, 'Model A', 1, 1),
(2, 'Model B', 2, 2);

INSERT INTO access_lists (user_id, model_id, read, edit) VALUES 
(1, 1, TRUE, TRUE),  	-- User1 has full access to Model A
(2, 1, TRUE, FALSE), 	-- User2 can only read Model A
(2, 2, TRUE, TRUE),  	-- User2 has full access to Model B
(3, 2, FALSE, FALSE); 	-- User3 can not read and edit Model B

-- ADD OBJECT TYPES, THEIR ENTITIES AND PARAMS

INSERT INTO objects (name, free_degrees) VALUES 
('Point', 2), 
('Segment', 4), 
('Circle', 3), 
('Arc', 5);

INSERT INTO entities (id, type_id) VALUES 
(1, 1),  -- Point
(2, 1),  -- Point
(3, 4),  -- Segment
(4, 3),  -- Circle
(5, 4);  -- Arc

INSERT INTO params (entity_id, name, value) VALUES 
(1, 'x', 5), 
(1, 'y', 5), 
(2, 'x', -1), 
(2, 'y', -3), 
(3, 'x_1', 10), 
(3, 'y_1', 10), 
(3, 'x_2', 0), 
(3, 'y_2', 0), 
(4, 'x', 12), 
(4, 'y', 5),  
(4, 'r', 8), 
(5, 'x', -8), 
(5, 'y', -8), 
(5, 'r', 8), 
(5, 'pole', 30),
(5, 'angle', 90);

-- ADD OBJECTS TO SET THE PLANE

INSERT INTO objects (name, free_degrees) VALUES 
('Point_3', 3), 
('Segment_3', 6)

INSERT INTO entities (id, type_id) VALUES 
(6, 5),  -- Point_3
(7, 6),  -- Segment_3
(8, 6);  -- Segment_3

-- ADD CONSTRAINTS AND PLANES

INSERT INTO constraint_types (id, name) VALUES 
(1, 'perpendicular'),
(2, 'length');

INSERT INTO constraints (id, constraint_type_id, first_object_id, second_object_id, value) VALUES 
(1, 1, 7, 8, NULL),		-- Perpendicular between 7 and 8 segments
(2, 2, 7, NULL, 1),		-- Length of 7 segments = 1
(3, 2, 8, NULL, 1); 	-- Length of 8 segments = 1

INSERT INTO planes(id, point_id, vector_x_id, vector_y_id) VALUES 
(1, 6, 7, 8), 		-- Plane through point 6 and between 7 and 8 segments
(2, NULL, 7, 8); 	-- Plane through point (0,0) and between 7 and 8 segments

-- ADD SKETCHES AND OBJECTS TO IT

INSERT INTO sketches(id, model_id, plane_id) VALUES 
(1, 1, 1), 		-- Add sketch to Model A from plane 1
(2, 2, 2); 		-- Add sketch to Model B from plane 2

INSERT INTO entity_sketch_relations(entity_id, sketch_id) VALUES 
(1, 1), 		-- Add point 1 to sketch 1
(3, 1), 		-- Add segment 3 to sketch 1
(4, 1), 		-- Add circle 4 to sketch 1
(2, 2), 		-- Add point 2 to sketch 2
(5, 2); 		-- Add arc 5 to sketch 2



