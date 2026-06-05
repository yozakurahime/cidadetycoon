CREATE TABLE `coreinventories` (
  `name` varchar(100) NOT NULL,
  `data` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `users` ADD `inventorysettings` LONGTEXT NULL DEFAULT NULL;

ALTER TABLE `items` 
  ADD `x` int(11) DEFAULT '1',
  ADD `y` int(11) DEFAULT '1',
  ADD `category` varchar(255) DEFAULT 'misc',
  ADD `componentTint` int(11) DEFAULT NULL,
  ADD `componentHash` varchar(255) DEFAULT NULL,
  ADD `backpackModel` int(11) DEFAULT NULL,
  ADD `backgroundTexture` int(11) DEFAULT NULL,
  ADD `description` varchar(255) NOT NULL DEFAULT 'An item'

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`, `x`, `y`, `category`, `componentTint`, `componentHash`, `backpackModel`, `backgroundTexture`, `description`) VALUES ('small_backpack', 'Backpack', '1', '0', '1', '3', '4', 'backpacks', NULL, NULL, '24', '2', 'Small Backpack'), ('medium_bag', 'Bag', '1', '0', '1', '4', '5', 'backpacks', NULL, NULL, '16', '0', 'Medium Bag'), ('large_backpack', 'Backpack', '1', '0', '1', '4', '5', 'backpacks', NULL, NULL, '13', '0', 'Large Backpack'), ('weapon_case', 'Weapon Case', '1', '0', '1', '9', '4', 'cases', NULL, NULL, NULL, NULL, 'Large weapon case'), ('storage_case', 'Storage Case', '1', '0', '1', '7', '5', 'cases', NULL, NULL, NULL, NULL, 'Storage Case'), ('hat', 'Hat', '1', '0', '1', '1', '1', 'hat', NULL, NULL, NULL, NULL, 'a hat'), ('tshirt', 'Shirt', '1', '0', '1', '1', '1', 'tshirt', NULL, NULL, NULL, NULL, 'a shirt'), ('torso', 'Torso', '1', '0', '1', '1', '1', 'torso', NULL, NULL, NULL, NULL, 'a torso'), ('pants', 'Pants', '1', '0', '1', '1', '1', 'pants', NULL, NULL, NULL, NULL, 'pants'), ('shoes', '', '1', '0', '1', '1', '1', 'shoes', NULL, NULL, NULL, NULL, 'An item'), ('watch', 'Watch', '1', '0', '1', '1', '1', 'watch', NULL, NULL, NULL, NULL, 'watch'), ('assaultrifle_extendedclip', 'Rifle EXT Clip', '1', '0', '1', '2', '2', 'component_clip', NULL, 'COMPONENT_ASSAULTRIFLE_CLIP_02', NULL, NULL, 'Attachment component'), ('assaultrifle_drum', 'Rifle Drum Clip', '1', '0', '1', '2', '2', 'component_clip', NULL, 'COMPONENT_ASSAULTRIFLE_CLIP_03', NULL, NULL, 'Attachment component'), ('assaultrifle_luxuryfinish', 'Rifle Luxury Finish', '1', '0', '1', '2', '2', 'component_finish', NULL, 'COMPONENT_ASSAULTRIFLE_VARMOD_LUXE', NULL, NULL, 'Attachment component'), ('rifle_suppressor', 'Rifle Suppressor', '1','0', '1', '2', '2', 'component_suppressor', NULL, 'COMPONENT_AT_AR_SUPP_02', NULL, NULL, 'Attachment component')