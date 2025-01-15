-- Добавляем юзеров, их модели, и права доступа

INSERT INTO users (id, username) VALUES 
(1, 'user1'), 
(2, 'user2'), 
(3, 'user3');

INSERT INTO models (id, name, creator_id, last_updator_id) VALUES 
(1, 'Model A', 1, 1),
(2, 'Model B', 2, 2);

INSERT INTO access_lists (user_id, model_id, read, edit) VALUES 
(1, 1, TRUE, TRUE),  	-- User1 имеет полный доступ к Model A
(2, 1, TRUE, FALSE), 	-- User2 может только видеть Model A
(2, 2, TRUE, TRUE),  	-- User2 имеет полный доступ к Model B
(3, 2, FALSE, FALSE); 	-- User3 не может ни читать, ни видеть Model B


-- Добавляем типы объектов и их экземпляры

INSERT INTO objects (name, free_degrees) VALUES 
('Point', 2), 
('Segment', 4), 
('Circle', 3), 
('Arc', 5);

INSERT INTO entities (id, object_id) VALUES 
(1, 1),  -- Point 1
(2, 1),  -- Point 2
(3, 2),  -- Segment 3
(4, 3),  -- Circle 4
(5, 4);  -- Arc 5


-- Добавляем параметры объектов 

INSERT INTO params (entity_id, name, value) VALUES 
(1, 'x', 5), 		-- Координаты Point 1
(1, 'y', 5), 
(2, 'x', -1), 		-- Координаты Point 2
(2, 'y', -3), 
(4, 'r', 8), 		-- Радиус Circle 4
(5, 'r', 8), 		-- Радиус Arc 5
(5, 'pole', 30),	-- Полюс Arc 5
(5, 'angle', 90);	-- Угол Arc 5

INSERT INTO constraint_types (id, name) VALUES 
(3, 'parent');		-- Отношение родитель / ребенок для задания нетривиальных примитивов

INSERT INTO constraints (id, constraint_type_id, fitst_entity_id, second_entity_id, value) VALUES 
(4, 3, 1, 3, 1),	-- Point 1 является родителем для Segment 3 (value = 1 - для упорядочивания родителей)
(5, 3, 2, 3, 2),	-- Point 2 является родителем для Segment 3 (value = 2 - для упорядочивания родителей)
					-- Таким образом однозначно определили отрезок Segment 3 через две точки - Point 1 и Point 2

(6, 3, 1, 4, NULL),	-- Point 1 является родителем для Circle 4 (value = NULL так как только один родительский объект)
					-- Таким образом однозначно определили окружность Circle 4 через центр Point 1 и радиус r (в табличке params)

(7, 3, 2, 5, NULL);	-- Point 2 является родителем для Arc 5 (value = NULL так как только один родительский объект)
					-- Таким образом однозначно определили дугу Arc 5 через центр Point 2, радиус r, полюс pole и угол angle (в табличке params)


-- Добавляем трехмерные объекты для задания плоскости

INSERT INTO objects (name, free_degrees) VALUES 
(5, 'Point_v3', 3), 	-- точка в трехмерном пространстве
(6, 'Segment_v3', 6);	-- отрезок в трехмерном пространстве

INSERT INTO entities (id, object_id) VALUES 
(6, 5),  	-- Point_v3 6 
(7, 5),  	-- Point_v3 7 
(8, 5),  	-- Point_v3 8 
(9, 6),  	-- Segment_v3 9
(10, 6);  	-- Segment_v3 10


-- Добавляем ограничения на объекты

INSERT INTO constraint_types (id, name) VALUES 
(1, 'perpendicular'),
(2, 'length');

INSERT INTO constraints (id, constraint_type_id, fitst_entity_id, second_entity_id, value) VALUES 
(1, 1, 9, 10, NULL),	-- Перпендикулярность между Segment_v3 9 and Segment_v3 10
(2, 2, 9, NULL, 1),		-- Длина 9 отрезка = 1 (нормировка)
(3, 2, 10, NULL, 1); 	-- Длина 10 отрезка = 1 (нормировка)


-- Добавляем параметры обьектов для трех точек и двух отрезков в трехмерном пространстве

INSERT INTO params (entity_id, name, value) VALUES 
(6, 'x', 5), 		-- Координаты Point_v3 6
(6, 'y', 5), 
(6, 'z', -1), 	
(7, 'x', 10), 		-- Координаты Point_v3 7
(7, 'y', 0), 
(7, 'z', 3), 	
(8, 'x', 4), 		-- Координаты Point_v3 8
(8, 'y', 1), 
(8, 'z', -5);

INSERT INTO constraints (id, constraint_type_id, fitst_entity_id, second_entity_id, value) VALUES 
(8, 3, 6, 9, 1),	-- Point_v3 6 является родителем для Segment_v3 9 (value = 1 - для упорядочивания родителей)
(9, 3, 7, 9, 2),	-- Point_v3 7 является родителем для Segment_v3 9 (value = 2 - для упорядочивания родителей)
					-- Таким образом однозначно определили отрезок Segment_v3 9 через две точки - Point_v3 6 и Point_v3 7

(10, 3, 7, 10, 1),	-- Point_v3 7 является родителем для Segment_v3 10 (value = 1 - для упорядочивания родителей)
(11, 3, 8, 10, 2);	-- Point_v3 8 является родителем для Segment_v3 10 (value = 2 - для упорядочивания родителей)
					-- Таким образом однозначно определили отрезок Segment_v3 10 через две точки - Point_v3 7 и Point_v3 9


-- Создаем плоскость по двум отрезкам и точке в трехмерном пространстве

INSERT INTO objects (id, name, free_degrees) VALUES 
(7, 'Plane_v3', 15); 	-- Плоскость для задания скетча

INSERT INTO entities (id, object_id) VALUES 
(11, 7);  	-- Plane_v3 11 

INSERT INTO constraints (id, constraint_type_id, fitst_entity_id, second_entity_id, value) VALUES 
(12, 3, 7, 11, 1),	-- Point_v3 7 является родителем для Plane_v3 11 (value = 1 - для упорядочивания родителей)
(13, 3, 9, 11, 2),	-- Segment_v3 9 является родителем для Plane_v3 11 (value = 2 - для упорядочивания родителей)
(14, 3, 10, 11, 3);	-- Segment_v3 10 является родителем для Plane_v3 11 (value = 3 - для упорядочивания родителей)
					-- Таким образом однозначно определили плоскость Plane_v3 11 через точку Point_v3 7 и два вектора - Segment_v3 9 и Segment_v3 10


-- Добавляем чертежи на плоскость и присоединяем к моделям 

INSERT INTO sketches(id, model_id, entity_id) VALUES 
(1, 1, 11), 		-- Добавляем Sketch 1 на плоскость Plane_v3 11 и присоединяем к модели Model A 
(2, 2, 11); 		-- Добавляем Sketch 2 на плоскость Plane_v3 11 и присоединяем к модели Model B


-- Добавляем объекты на чертежи

INSERT INTO entity_sketch_relations(entity_id, sketch_id) VALUES 
(1, 1), 		-- Добавляем Point 1 на чертеж Sketch 1
(1, 2), 		-- Добавляем Point 1 на чертеж Sketch 2
(3, 1), 		-- Добавляем Segment 3 на чертеж Sketch 1
(4, 1), 		-- Добавляем Cirlce 4 на чертеж Sketch 1
(2, 2), 		-- Добавляем Point 2 на чертеж Sketch 2
(5, 2); 		-- Добавляем Arc 5 на чертеж Sketch 2


