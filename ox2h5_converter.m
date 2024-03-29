% %function [ MapData,MicroscopeData,PhaseData,EBSPData ] = CTF_HDF5( InputUser )
% 
clc;clear

%% Inputs required
directory= 'Y:\Xinrui\Crossbeam\Xinrui\016\Unprocessed 1\';   %Remember '\' at the end
filename='Map Data 1';
extension_for_images_directory='_Images';   %Any extenstion names to images directory
image_file_type='.tiff';
%% 

InputUser.CTF_dir=directory;
InputUser.CTF_File=strcat(directory,filename,'.ctf');
InputUser.OI_images_extension=extension_for_images_directory;
InputUser.imagesdirectory=[InputUser.CTF_dir filename InputUser.OI_images_extension];
addpath(genpath(InputUser.CTF_dir));
%InputUser.CTF_File='test1.ctf';
tic 
OutputUser.name = filename;
OutputUser.HDF5_File=[InputUser.CTF_dir OutputUser.name '.h5'];

 
 if exist(InputUser.CTF_File)~=2 
     error('.ctf file not found');
     if exist(InputUser.imagesdirectory)~=7
         error('Could not locate the directory with images. Place check the input variables');
     end
 end
 
 if exist(OutputUser.HDF5_File,'file')
    delete(OutputUser.HDF5_File)
end
 

%Read CTF and save data to workspace
fid = fopen(InputUser.CTF_File,'rb');
strg = textscan(fid,'%s','Delimiter','\n');
strg=strg{1,1};
fclose(fid);

nodatax=str2double(strtok(validatestring('XCells',strg),'XCells'));
nodatay=str2double(strtok(validatestring('YCells',strg),'YCells'));
stepx=str2double(strtok(validatestring('XStep',strg),'XStep'));
stepy=str2double(strtok(validatestring('YStep',strg),'YStep'));
nophases=str2double(strtok(validatestring('Phases',strg),'Phases'));
gridtype = strsplit(validatestring('JobMode',strg));
gridtype = gridtype{2};

filedim=size(strg);  %%rows and col dimensions
ndatatot=nodatax*nodatay;
numdata=zeros(ndatatot,11);
rowcounter=0;
for i=1:filedim(1)
    ndat=str2num(strg{i});
    if (~isempty(ndat))
        rowcounter = rowcounter+1 ;
        numdata(rowcounter,:)=ndat;
    end
end
Xmax=max(numdata(:,2));
Ymax=max(numdata(:,3));

if size(dir([InputUser.imagesdirectory '/*' image_file_type]),1)~=ndatatot
    error('Image count does not match with the map size')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Add string type data to file using the H5D package

%Create HDF5 file with Version and Manufacturer strings
disp('Creating the file')
fid = H5F.create(OutputUser.HDF5_File);
type_id = H5T.copy('H5T_C_S1');
space_id = H5S.create_simple(1,1,1);
space_id = H5S.create('H5S_SCALAR');
dcpl = 'H5P_DEFAULT';



H5T.set_size(type_id, 5);
dset_id = H5D.create(fid,'Version',type_id,space_id,dcpl);
H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dcpl,'Aztec');

H5T.set_size(type_id, 18);
dset_id = H5D.create(fid,'Manufacturer',type_id,space_id,dcpl);
H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dcpl,'Oxford Instruments');

H5S.close(space_id)
H5T.close(type_id)
H5D.close(dset_id)
%Create groups for SEM, EBSD data and subgroups for phases. coordinate
%systems
gid1= H5G.create(fid,filename,dcpl,dcpl,dcpl);
    gid1_1=H5G.create(gid1,'SEM',dcpl,dcpl,dcpl);
    H5G.close(gid1_1);
    gid1_2=H5G.create(gid1,'EBSD',dcpl,dcpl,dcpl);
    gid1_2_1=H5G.create(gid1_2,'Header',dcpl,dcpl,dcpl);
        type_id = H5T.copy('H5T_C_S1');
        H5T.set_size(type_id, length(gridtype));
        space_id = H5S.create_simple(1,1,1);
        dset_id = H5D.create(gid1_2_1,'GridType',type_id,space_id,dcpl);
        H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dcpl,gridtype);
        
        H5T.set_size(type_id, length(InputUser.CTF_File));
        dset_id = H5D.create(gid1_2_1,'OriginalFile',type_id,space_id,dcpl);
        H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dcpl,InputUser.CTF_File);
        H5S.close(space_id)
        H5T.close(type_id)
        H5D.close(dset_id)
        
        
        gid1_2_1_1=H5G.create(gid1_2_1,'Phases',dcpl,dcpl,dcpl);
        for i=1:nophases
            gid1_2_1_1_1=H5G.create(gid1_2_1_1,int2str(i),dcpl,dcpl,dcpl);
            loc=find(ismember(strg,validatestring('Phases',strg)))+i;
            string=strg(loc);
            string=string{1,1};
            string=strsplit(string,'\t');
            type_id = H5T.copy('H5T_C_S1');
            space_id = H5S.create_simple(1,1,1);
            H5T.set_size(type_id, length(string{1,3}));
            dset_id = H5D.create(gid1_2_1_1_1,'Name',type_id,space_id,dcpl);
            H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dcpl,string{1,3});
            H5S.close(space_id)
            H5T.close(type_id)
            H5D.close(dset_id)
                       
        
            H5G.close(gid1_2_1_1_1);
        end
        H5G.close(gid1_2_1_1)
        gid1_2_1_2=H5G.create(gid1_2_1,'Coordinate Systems',dcpl,dcpl,dcpl);
        type_id = H5T.copy('H5T_C_S1');
        space_id = H5S.create_simple(1,1,1);
        H5T.set_size(type_id, 45);
        dset_id = H5D.create(gid1_2_1_2,'Tutorial paper on EBSD',type_id,space_id,dcpl);
        H5D.write(dset_id,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dcpl,'https://doi.org/10.1016/j.matchar.2016.04.008');
        H5S.close(space_id)
        H5T.close(type_id)
        H5D.close(dset_id)
        H5G.close(gid1_2_1_2);
        
        
        
    H5G.close(gid1_2_1);
    gid1_2_2=H5G.create(gid1_2,'Data',dcpl,dcpl,dcpl);
    H5G.close(gid1_2_2);
    H5G.close(gid1_2);
    
H5G.close(gid1);
H5F.close(fid);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Add numerical type data to file using the inbuilt H5 write
%Phase data
warning('off','all');
disp('Writing Phase Data')
%supress warnings for double to int conversion
for i=1:nophases
    loc=find(ismember(strg,validatestring('Phases',strg)))+i;
    string=strg(loc);
    string=string{1,1};
    string=strsplit(string,'\t');
    t=horzcat(cellfun(@str2double,strsplit(string{1,1},';')),cellfun(@str2double,strsplit(string{1,2},';')));
    
    h5create(OutputUser.HDF5_File,strcat('/',filename,'/EBSD/Header/Phases/',int2str(i),'/LatticeConstants'),[1,6]);
    h5write(OutputUser.HDF5_File,strcat('/',filename,'/EBSD/Header/Phases/',int2str(i),'/LatticeConstants'),t);
    
    h5create(OutputUser.HDF5_File,strcat('/',filename,'/EBSD/Header/Phases/',int2str(i),'/Laue Group'),1,'Datatype','int32');
    h5write(OutputUser.HDF5_File,strcat('/',filename,'/EBSD/Header/Phases/',int2str(i),'/Laue Group'),str2num(string{1,4}));
    
    h5create(OutputUser.HDF5_File,strcat('/',filename,'/EBSD/Header/Phases/',int2str(i),'/Space Group'),1,'Datatype','int32');
    h5write(OutputUser.HDF5_File,strcat('/',filename,'/EBSD/Header/Phases/',int2str(i),'/Space Group'),str2num(string{1,5}));
end


%Add bruker style co-ordinate system (necessary for xEBSD code)

if exist('Bruker_coordinate_system.tiff')~=2
     error('Could not locate the Bruker coordinate file .tiff. Please add it to this directory');
end

%image=imread('Bruker_coordinate_system.tiff');
%h5create(OutputUser.HDF5_File,['/' filename '/EBSD/Header/Coordinate Systems/ESPRIT Coordinates'],[size(image,1),size(image,2)]);
%h5write(OutputUser.HDF5_File,['/' filename '/EBSD/Header/Coordinate Systems/ESPRIT Coordinates/'],image);

%h5create(OutputUser.HDF5_File,['/' filename '/EBSD/Header/Coordinate Systems/ID/'],1);
%h5write(OutputUser.HDF5_File,['/' filename '/EBSD/Header/Coordinate Systems/ID/'],5);



%Add /EBSD/Header data
disp('Adding Header Data')
% Other EBSD/Header/ data
headerpath = strcat(strcat('/',filename,'/EBSD/Header/'));

string = validatestring('Euler',strg);
string=strsplit(string,'\t');
loc=find(ismember(string,'KV'));
h5create(OutputUser.HDF5_File,[headerpath,'KV'],1);
h5write(OutputUser.HDF5_File,[headerpath,'KV'],str2double(string{1,loc+1}));


try
    DetectorOrientation = [str2double(string(15)),str2double(string(17)),str2double(string(19))];
    DetectorOrientation=repmat(DetectorOrientation,5,1);
    DetectorOrientation=DetectorOrientation-repmat([0;90;180;270;360],1,3);
    DetectorOrientation = min(abs(DetectorOrientation));
    h5create(OutputUser.HDF5_File,[headerpath,'CameraTilt'],1);
    h5write(OutputUser.HDF5_File,[headerpath,'CameraTilt'],DetectorOrientation(2));
    
catch 
    disp('Detector Orientation not found in file. Will approximate to 6 deg ');
    h5create(OutputUser.HDF5_File,[headerpath,'CameraTilt'],1);
    h5write(OutputUser.HDF5_File,[headerpath,'CameraTilt'],6.0);

end

loc=find(ismember(string,'Mag'));
h5create(OutputUser.HDF5_File,[headerpath,'Magnification'],1);
h5write(OutputUser.HDF5_File,[headerpath,'Magnification'],str2double(string{1,loc+1}));

loc=find(ismember(string,'TiltAngle'));
h5create(OutputUser.HDF5_File,[headerpath,'SampleTilt'],1);
h5write(OutputUser.HDF5_File,[headerpath,'SampleTilt'],str2double(string{1,loc+1}));


loc=find(ismember(string,'WorkingDistance'));
if isempty(loc)
    h5create(OutputUser.HDF5_File,[headerpath,'WD'],1);
    h5write(OutputUser.HDF5_File,[headerpath,'WD'],0.0);
else
    h5create(OutputUser.HDF5_File,[headerpath,'WD'],1);
    h5write(OutputUser.HDF5_File,[headerpath,'WD'],str2double(string{1,loc+1}));
end


h5create(OutputUser.HDF5_File,[headerpath,'XSTEP'],1);
h5write(OutputUser.HDF5_File,[headerpath,'XSTEP'],stepx);

h5create(OutputUser.HDF5_File,[headerpath,'YSTEP'],1);
h5write(OutputUser.HDF5_File,[headerpath,'YSTEP'],stepy);

h5create(OutputUser.HDF5_File,[headerpath,'NCOLS'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'NCOLS'],nodatax);

h5create(OutputUser.HDF5_File,[headerpath,'NPoints'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'NPoints'],ndatatot);

h5create(OutputUser.HDF5_File,[headerpath,'NROWS'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'NROWS'],nodatay);


%%%Uses Natural sorting instead of string sort
%InputUser.imagesdirectory=sort(InputUser.imagesdirectory,'ascend');
%FileNames=dir([InputUser.imagesdirectory '/*' image_file_type]);
FileNames = dir(fullfile(InputUser.imagesdirectory,strcat('*',image_file_type)));
FileNames = natsortfiles(FileNames);


string = imfinfo(FileNames(1).name);            
PatternHeight = string.Height;
PatternWidth = string.Width;

h5create(OutputUser.HDF5_File,[headerpath,'PatternHeight'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'PatternHeight'],string.Height);

h5create(OutputUser.HDF5_File,[headerpath,'PatternWidth'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'PatternWidth'],string.Width);

h5create(OutputUser.HDF5_File,[headerpath,'DetectorFullHeightMicrons'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'DetectorFullHeightMicrons'],string.Height);

h5create(OutputUser.HDF5_File,[headerpath,'DetectorFullWidthMicrons'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'DetectorFullWidthMicrons'],string.Width);

h5create(OutputUser.HDF5_File,[headerpath,'MADMax'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'MADMax'],1.0);

h5create(OutputUser.HDF5_File,[headerpath,'MapStepFactor'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'MapStepFactor'],1.0);

h5create(OutputUser.HDF5_File,[headerpath,'MaxRadonBandCount'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'MaxRadonBandCount'],12);

h5create(OutputUser.HDF5_File,[headerpath,'MinIndexedBands'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'MinIndexedBands'],5);


h5create(OutputUser.HDF5_File,[headerpath,'PixelByteCount'],1,'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'PixelByteCount'],1);

h5create(OutputUser.HDF5_File,[headerpath,'SEM Image'],[nodatay nodatax 3],'Datatype','int32');
h5write(OutputUser.HDF5_File,[headerpath,'SEM Image'],zeros(nodatay,nodatax,3));


h5create(OutputUser.HDF5_File,[headerpath,'SEPixelSizeX'],1);
h5write(OutputUser.HDF5_File,[headerpath,'SEPixelSizeX'],stepx);

h5create(OutputUser.HDF5_File,[headerpath,'SEPixelSizeY'],1);
h5write(OutputUser.HDF5_File,[headerpath,'SEPixelSizeY'],stepy);

h5create(OutputUser.HDF5_File,[headerpath,'TopClip'],1);
h5write(OutputUser.HDF5_File,[headerpath,'TopClip'],0);

h5create(OutputUser.HDF5_File,[headerpath,'UnClippedPatternHeight'],1);
h5write(OutputUser.HDF5_File,[headerpath,'UnClippedPatternHeight'],string.Height);

h5create(OutputUser.HDF5_File,[headerpath,'ZOffset'],1);
h5write(OutputUser.HDF5_File,[headerpath,'ZOffset'],0);

%Adding /EBSD/Data data
headerpath = strcat(strcat('/',filename,'/EBSD/Data/'));

disp('Adding Map Data')

h5create(OutputUser.HDF5_File,[headerpath,'MAD'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'MAD'],numdata(:,9));

h5create(OutputUser.HDF5_File,[headerpath,'NIndexedBands'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'NIndexedBands'],numdata(:,4));

h5create(OutputUser.HDF5_File,[headerpath,'Phase'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'Phase'],numdata(:,1));

h5create(OutputUser.HDF5_File,[headerpath,'MADPhase'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'MADPhase'],numdata(:,1));

h5create(OutputUser.HDF5_File,[headerpath,'RadonQuality'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'RadonQuality'],numdata(:,10));

h5create(OutputUser.HDF5_File,[headerpath,'RadonBandCount'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'RadonBandCount'],numdata(:,4));

h5create(OutputUser.HDF5_File,[headerpath,'phi1'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'phi1'],numdata(:,6));

h5create(OutputUser.HDF5_File,[headerpath,'PHI'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'PHI'],numdata(:,7));

h5create(OutputUser.HDF5_File,[headerpath,'phi2'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'phi2'],numdata(:,8));

h5create(OutputUser.HDF5_File,[headerpath,'X BEAM'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'X BEAM'],round(numdata(:,2)/stepx));

h5create(OutputUser.HDF5_File,[headerpath,'Y BEAM'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'Y BEAM'],round(numdata(:,3)/stepy));

h5create(OutputUser.HDF5_File,[headerpath,'X SAMPLE'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'X SAMPLE'],flip(numdata(:,2)+stepx));

h5create(OutputUser.HDF5_File,[headerpath,'Y SAMPLE'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'Y SAMPLE'],numdata(:,3));

h5create(OutputUser.HDF5_File,[headerpath,'Z SAMPLE'],[ndatatot 1] );
h5write(OutputUser.HDF5_File,[headerpath,'Z SAMPLE'],zeros(ndatatot,1));

%Adding patterns and PC X,Y,Z
headerpath = strcat(strcat('/',filename,'/EBSD/Data/'));


h5create(OutputUser.HDF5_File,[headerpath,'PCX'],[ndatatot 1] );
h5create(OutputUser.HDF5_File,[headerpath,'PCY'],[ndatatot 1] );
h5create(OutputUser.HDF5_File,[headerpath,'DD'],[ndatatot 1] );
PCXpu=[];
PCYpu=[];
DDpu=[];

string = imfinfo(FileNames(1).name);
datatype=['uint' num2str(string.BitDepth)];
PW=string.Width;
PH=string.Height;


% the following method to add raw EBSPs works in pairs of 2 to take in
% account the 3rd dimension and checks for odd number of patterns to add
% the last set.
%h5create(OutputUser.HDF5_File,[headerpath,'RawPatterns'],[Inf Inf Inf],'ChunkSize',[PH PW 2],'Datatype',datatype);
h5create(OutputUser.HDF5_File,[headerpath,'RawPatterns'],[PW PH ndatatot],'Datatype',datatype);
h=waitbar(0,'Adding raw EBSPs and PCs to file ...');
for i=1:2:length(FileNames)-1
     RawPattern=cat(3,imread(FileNames(i).name)',imread(FileNames(i+1).name)');
     h5write(OutputUser.HDF5_File,[headerpath,'RawPatterns'],RawPattern,[1 1 i],[PW PH 2]);
     string1 = imfinfo(FileNames(i).name);
     string1 = string1.UnknownTags.Value;
     PCX1=str2double(string1((strfind(string1,'<pattern-center-x-pu>')+21):(strfind(string1,'</pattern-center-x-pu>')-1)));
     PCXpu=[PCXpu;(PCX1*PW)/PW];
     PCY1=str2double(string1((strfind(string1,'<pattern-center-y-pu>')+21):(strfind(string1,'</pattern-center-y-pu>')-1)));
     PCYpu=[PCYpu;(PH-(PCY1*PW))/PH];
     DD1=str2double(string1((strfind(string1,'<detector-distance-pu>')+22):(strfind(string1,'</detector-distance-pu>')-1)));
     DDpu=[DDpu;(DD1*PW)/PH];
     string2 = imfinfo(FileNames(i+1).name);
     string2 = string2.UnknownTags.Value;
     PCX2=str2double(string2((strfind(string2,'<pattern-center-x-pu>')+21):(strfind(string2,'</pattern-center-x-pu>')-1)));
     PCXpu=[PCXpu;(PCX2*PW)/PW];
     PCY2=str2double(string2((strfind(string2,'<pattern-center-y-pu>')+21):(strfind(string2,'</pattern-center-y-pu>')-1)));
     PCYpu=[PCYpu;(PH-(PCY2*PW))/PH];
     DD2=str2double(string2((strfind(string2,'<detector-distance-pu>')+22):(strfind(string2,'</detector-distance-pu>')-1)));
     DDpu=[DDpu;(DD2*PW)/PH];
     waitbar(i/length(FileNames),h,sprintf('Adding raw EBSPs and PCs to file ... %3.2f %%',(i*100/length(FileNames))))
 end
 
 if mod(ndatatot,2)~=0
     i=i+1;
     RawPattern=cat(3,imread(FileNames(i).name),imread(FileNames(i+1).name));
     h5write(OutputUser.HDF5_File,[headerpath,'RawPatterns'],RawPattern,[1 1 i], [PW PH 2]);
     string1 = imfinfo(FileNames(i+1).name);
     string1 = string1.UnknownTags.Value;
     PCX1=str2double(string1((strfind(string1,'<pattern-center-x-pu>')+21):(strfind(string1,'</pattern-center-x-pu>')-1)));
     PCXpu=[PCXpu;(PCX1*PW)/PW];
     PCY1=str2double(string1((strfind(string1,'<pattern-center-y-pu>')+21):(strfind(string1,'</pattern-center-y-pu>')-1)));
     PCYpu=[PCYpu;(PH-(PCY1*PW))/PH];
     DD1=str2double(string1((strfind(string1,'<detector-distance-pu>')+22):(strfind(string1,'</detector-distance-pu>')-1)));
     DDpu=[DDpu;(DD1*PW)/PH];
     
 end
h5write(OutputUser.HDF5_File,[headerpath,'PCX'],PCXpu);
h5write(OutputUser.HDF5_File,[headerpath,'PCY'],PCYpu);
h5write(OutputUser.HDF5_File,[headerpath,'DD'],DDpu);
close(h)
disp('Done !')

