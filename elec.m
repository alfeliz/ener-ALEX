#! /usr/bin/octave
# octave script
# elec.m Take the electricity folders for each shot in folders separated by voltage, 
#		and extract the real value of the energy absorved by the wire



#Clear memory:
clear;

#Necessary variables that must be created before:
directories = {};
vector = [];
Voltages = [];

###################################################################
#
#First, read the files in here and check which ones are folders:
#
###################################################################

#Files and folders in actual root folder:
archivia = dir(); 

#THIS ONLY FOR LINUX, IN OTHER SYSTEMS, CHECK YOURSELF:
archivia(1) = archivia(2) = []; #Remove the directories "." and ".." 

#For all the files/folders in root folder, select only folders:
for i=1:length(archivia) 
	if archivia(i).isdir == 1 #Folder!
		directories(length(directories)+1) = archivia(i);
	endif;
endfor;

#Number of folders in root folder:
#Suposely, these folders are the ones with names with voltages. (10kV, 20kV and so on.)
num_dir = size(directories)(2);

for i=1:num_dir #for every folder, check shot folders in:
#Make 0 the data vectors every time, or they will accumulate previous iteration values:
	energias = []; #Electric energies vector
	err_energias = []; #Error, understood as typical deviation vector
	disparos = []; #Shot names vector
	
	###################################################################
	# Now, for every folder with shots, read the shots and 
	#		other folders list and identify the electricity 
	#		shot folders(Finished in -ELEC)
	###################################################################
	
	#Read all the folders with shots data within the voltage folder:
	elec_files = readdir(directories{i}.name);
	
	#Identify the folders with electricity data:
	idx =   strncmpi(elec_files,'ALEX',4); %Find the strings in the cell array that have ALEX in the first 4 positions. ALEX shots electricity folders
	ALEX_carpetas = char(elec_files{idx,1}); %Transform the strings into adequate char strings. Or whatever. Here is a list with the ALEX shots folders.
	
	#With all the folders with electricity data shots:
	if (size(ALEX_carpetas)(1)!=0) #There are files in the folder
		###################################################################
		# When there is electricity data, look for the voltage and 
		#		current already calibrated *.CSV files and find power 
		#		and energy by integration of V(t)*I(t)
		###################################################################
		
		#Folder with shots name:
		disp(directories{i}.name(1:4))
		
		#Vector with voltages of the shot:
		#(IT WORKS ONLY IF THE FOLDERS WERE 
		#EVERYTHING IS CLASSIFIED ARE CALLED 10kV, 20kV, ETC)
		Voltages = [Voltages; char(directories{i}.name(1:4))];
	
		for j=1:size(ALEX_carpetas)(1) #In every electric folder:
		###########################################################
		# Here work with the electricity data first:
		###########################################################
		
		#Tell with what shot you do things:
		disp(ALEX_carpetas(j,:))
		
		#Vector with shot names:
		disparos = [disparos; ALEX_carpetas(j,:)];
		
		#Data folder structure with files and folders and all:
		data_folder = readdir(horzcat(char(pwd), "/", directories{i}.name, "/", ALEX_carpetas(j,:)));

		#reading the Worked data folder(always finishes with "_WORKED" and is in the second position...)
		Worked_folder = readdir(horzcat(char(pwd), "/", directories{i}.name, "/", ALEX_carpetas(j,:), "/", char(data_folder(2))));
		
		#Iterate until you find the voltage and current files:
		for k=3: length(Worked_folder) #In all the files in here, but "." and ".."
			end_file = char(Worked_folder(k));
			if (end_file(end-8:end)=="DI03 .csv") #voltage 03 (Close to Spark gap)
				#file name:
				file_name = horzcat(char(pwd), "/", directories{i}.name, "/", ALEX_carpetas(j,:), "/", char(data_folder(2)), "/", char(Worked_folder(k)));
				#Reading the filename:
				V03 = load(file_name);
			elseif (end_file(end-8:end)=="DI04 .csv") #voltage 04 (Close to earth pole)
				#file name:
				file_name = horzcat(char(pwd), "/", directories{i}.name, "/", ALEX_carpetas(j,:), "/", char(data_folder(2)), "/", char(Worked_folder(k)));
				#Reading the filename:
				V04 = load(file_name);
			elseif (end_file(end-8:end)=="Curre.csv") #Current
				#file name:
				file_name = horzcat(char(pwd), "/", directories{i}.name, "/", ALEX_carpetas(j,:), "/", char(data_folder(2)), "/", char(Worked_folder(k)));
				#Reading the filename:
				Curr = load(file_name);
			endif;
		endfor; #for k
		
		###########################################################
		# Calculate the voltage drop, multiply it by current 
		#		and integrate the resulting power:
		###########################################################
		
		#Voltage drop:
		V_drop = V03(:,2) - V04(:,2);

		
		#Removing in current the baseline:
		Current = (Curr(:,2)-mean(Curr(1:5,2))).*0.5; #the 0.5 is to compensate the impedance of the scope.
		
		#Power, power:
		Pow = V_drop.*Current;
		
		
		#Total energy in time (Joules):
		Ener = cumtrapz(Pow)*abs(V03(2,1)-V03(1,1));
		
		%Ener(end-5:end)
		
		#chekin issues at high voltages:
		%plot(V03(:,1),Ener)
		%print("Ener-02.pdf", "-append")
		
		#Let's take the average of the last 50 points:
		En = mean(Ener(end-50:end));
		#It's error, considered as 2*typ. deviation:
		err_En = 2 * std(Ener(end-50:end));
		
		#Storing data into vector:
		energias =[energias; En];
		err_energias = [err_energias; err_En];
		
		disp("Joules: ")
		disp(En)
		
		disp("Error:")
		disp(err_En)
		endfor;#for j


	####################################################
	# Final data vectors and structure (for each shot)
	####################################################

	#Structure with the data for each voltage:
	#(Not used now. Perhaps in later versions.)
	#The "l" must be changed if everything will be stored.
	for l=1:rows(disparos)
		todo.disparos{l} = disparos(l,:);
		todo.energias{l} = energias(l);
		todo.errores{l} = err_energias(l);
	endfor;	

	#Matrix with energies and voltages from these energies to be saved:
	vector = [energias(:), err_energias(:), sqrt(energias(:))];
	
	
	########################
	#Saving the files:
	########################
	
	#File name:
	fil_name = strcat(Voltages(i,:), ".txt");
	
	#Opening the file:
	salida = fopen(fil_name,"w");
	
	#First line of the file (Info over what is stored):
	fdisp(salida, "Energías(J) Err_energ(J) Volt(kV)");
	
	redond = [3 3 3]; %Saved precision 
	
	display_rounded_matrix(vector, redond, salida); %This function is not made by me.
	
	fdisp(salida, "\n Media (Ener.(J) y Volt.(kV)):");
	
	fdisp(salida, [mean(energias), mean(sqrt(energias(:)))] );
	
	#Close the file:
	fclose(salida);
	
	#display in the screen checking info:
	disp(strcat(fil_name, " saved"));

	endif; #if (size(ALEX_...

endfor; #For num_dir







#That's...that's all folks!!!
