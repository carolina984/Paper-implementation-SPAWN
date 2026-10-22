function [anchor_pos] = anchors_data()
margin = 15;
square_size = 100;

anchor_pos = zeros(13,2);

anchor_pos(1, :) = [margin, margin];
anchor_pos(7, :) = [square_size/2, square_size/2];
anchor_pos(3, :) = [square_size - margin, margin];
anchor_pos(11, :) = [margin, square_size - margin];
anchor_pos(13, :) = [square_size - margin, square_size - margin];


anchor_pos(2, :) = (anchor_pos(1, :) + anchor_pos(3, :))/2;
anchor_pos(6, :) = (anchor_pos(1, :) + anchor_pos(11, :))/2;
anchor_pos(12, :) = (anchor_pos(11, :) + anchor_pos(13, :))/2;
anchor_pos(8, :) = (anchor_pos(3, :) + anchor_pos(13, :))/2;


anchor_pos(4, :) = [(anchor_pos(1, 1) + anchor_pos(2, 1))/2, (anchor_pos(6, 2) + anchor_pos(1, 2))/2];
anchor_pos(5, :) = [(anchor_pos(2, 1) + anchor_pos(3, 1))/2, (anchor_pos(6, 2) + anchor_pos(1, 2))/2];
anchor_pos(9, :) = [(anchor_pos(1, 1) + anchor_pos(2, 1))/2, (anchor_pos(11, 2) + anchor_pos(6, 2))/2];
anchor_pos(10, :) = [(anchor_pos(2, 1) + anchor_pos(3, 1))/2, (anchor_pos(11, 2) + anchor_pos(6, 2))/2];

end
