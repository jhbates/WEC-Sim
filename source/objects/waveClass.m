%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2014 National Renewable Energy Laboratory and National 
% Technology & Engineering Solutions of Sandia, LLC (NTESS). 
% Under the terms of Contract DE-NA0003525 with NTESS, 
% the U.S. Government retains certain rights in this software.
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
% http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


classdef waveClass<handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The  ``waveClass`` creates a ``waves`` object saved to the MATLAB
    % workspace. The ``waveClass`` includes properties and methods used
    % to define WEC-Sim's wave input. 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (SetAccess = 'public', GetAccess = 'public')         
        % The following properties are public, and can be defined in the
        % ``wecSimInputFile.m``.
        type = 'NOT DEFINED'; % (`string`) Specifies the wave type, options include:``noWave``, ``noWaveCIC``, ``regular``, ``regularCIC``, ``irregular``, ``spectrumImport``, or ``etaImport``. Default = ``'NOT DEFINED'``
        T = 'NOT DEFINED';  % (`float`) Wave period [s] . Defined as wave period for ``regular``, peak period for ``irregular``, or period of BEM data used for hydrodynamic coefficients for ``noWave``. Default = ``'NOT DEFINED'``
        H = 'NOT DEFINED';  % (`float`) Wave height [m]. Defined as wave height for ``regular``, or significant wave height for ``irregular``. Default =  ``'NOT DEFINED'``
        spectrumType = 'NOT DEFINED';  % (`string`) Specifies the wave spectrum type, options inlcude:``PM`` or ``JS``. Default = ``'NOT DEFINED'``
        gamma = [];         % (`float`) Defines gamma, only used for ``JS`` wave spectrum type. Default = ``[]``
        phaseSeed = 0;      % (`integar`) Defines the random phase seed, only used for ``irregular`` and ``spectrumImport`` waves. Default = ``0``
        spectrumDataFile = 'NOT DEFINED'; % (`string`) Data file that contains the spectrum data file.  Default = ``'NOT DEFINED'``        
        etaDataFile = 'NOT DEFINED'; % (`string`) Data file that contains the times-series data file. Default = ``'NOT DEFINED'``
        freqRange = [];     % (`2x1 vector`) Min and max wave frequency [rad/s], only used for ``irregular`` and ``spectrumImport``. If not specified, the BEM data frequency range is used. Default = ``[]``
        numFreq = [];       % (`integar`) Number of interpolated wave frequencies, only used for ``irregular`` and ``spectrumImport``. Number of frequencies used varies depending on ``freqDisc``, 1000 for ``'Traditional'``, and 500 for ``'EqualEnergy'`` and ``Imported``. Default = ``[]``
        waveDir = 0;        % (`float`) Incident wave direction(s) [deg]. Incident wave direction defined using WEC-Sim global coordinate system. Should be defined as a column vector for more than one wave direction. Default = ``0``
        waveSpread = 1;     % (`float`) Wave Spread probability associated with wave direction(s). Should be defined as a column vector for more than one wave direction. Default = ``1``
        viz = struct( 'numPointsX', 50, ...
                      'numPointsY', 50 ); % (`structure`) Defines visualization options, structure contains the fields ``numPointsX`` for the number of visualization points in x direction, and ``numPointsY`` for the number of visualization points in y direction. 
        statisticsDataLoad = []; % (`string`) File name from which to load wave statistics data. Default = ``[]``        
        freqDisc = 'EqualEnergy'; % (`string`) Method of frequency discretization for irregular waves, options include: ``'EqualEnergy'`` or ``'Traditional'``. Default = ``'EqualEnergy'``
        wavegauge1loc = [0,0];  % (`1x2 vector`) Wave gauge 1 [x,y] location [m]. Default = ``[0,0]``
        wavegauge2loc = [0,0];  % (`1x2 vector`) Wave gauge 2 [x,y] location [m]. Default = ``[0,0]``
        wavegauge3loc = [0,0];  % (`1x2 vector`) Wave gauge 3 [x,y] location [m]. Default = ``[0,0]``
        currentOption = 3;      % (`integar`) Define the sub-surface current model to be used in WEC-Sim, options include: ``0`` for depth-independent model, ``1`` for 1/7 power law variation with depth, ``2`` for linear variation with depth, or ``3`` for no current. Default = ``3`` 
        currentSpeed = 0;       % (`float`) Current seed [m/s]. Surface current speed that is uniform along the water column. Default = ``0``
        currentDirection = 0;   % (`float`) Current direction [deg]. Surface current direction defined using WEC-Sim global coordinate system. Default = ``0``
        currentDepth = 0;       % (`float`) Current depth [m]. Define the depth over which the sub-surface current is modeled. Must be defined for options ``1`` and ``2``. The current is not calculated for any depths greater than the specified current depth. Default = ``0``
    end
    
    
    properties (SetAccess = 'private', GetAccess = 'public')       
        % The following properties are private, for internal use by WEC-Sim
        typeNum = [];       % Number to represent different type of waves        
        bemFreq = [];       % Number of wave frequencies from BEM
        waterDepth = [];    % Water depth (from BEM) [m] 
        deepWaterWave = []; % Deep water or not, depending on input from WAMIT, NEMOH and AQWA
        waveAmpTime = [];   % Wave elevation time history [m] 
        waveAmpTime1 = [];  % Wave elevation time history at a wave gauge 1 location specified by user [m] 
        waveAmpTime2 = [];  % Wave elevation time history at a wave gauge 2 location specified by user [m] 
        waveAmpTime3 = [];  % Wave elevation time history at a wave gauge 3 location specified by user [m] 
        A = [];             % Wave amplitude [m]. For regular waves or 2*(wave spectrum vector) for irregular waves
        w = [];             % Wave frequency (regular waves) or wave frequency vector (irregular waves) [rad/s] 
        phase = 0;          % Wave phase [rad] . Only used for ``irregular`` waves.
        dw = 0;             % Frequency spacing [rad] for ``irregular`` waves.
        k = [];             % Wave Number
        S = [];             % Wave Spectrum [m^2-s/rad] for ``Traditional``
        Pw = [];            % Wave Power Per Unit Wave Crest [W/m]
    end
    
    methods (Access = 'public')
        function obj = waveClass(type)
            % This method initilizes the ``waveClass`` and creates a
            % ``waves`` object.          
            %
            % Parameters
            % ------------
            %     type : string
            %         String specifying the wave type, options include:
            %
            %           noWave 
            %               No waves      
            % 
            %           noWaveCIC  
            %               No waves but with the Convolution Integral Calculation to calculate radiation effects   
            % 
            %           regular 
            %               Regular waves
            % 
            %           regularCIC 
            %               Regular waves with Convolution Integral Calculation to calculate radiation effects
            % 
            %           irregular  
            %           	Irregular Waves
            % 
            %           spectrumImport 
            %           	Irregular Waves with predefined phase
            % 
            %           etaImport 
            %               Irregular Waves with predefined elevation
            %
            % Returns
            % ------------
            %     waves : obj
            %         waveClass object         
            %

            obj.type = type;
            switch obj.type
                case {'noWave'}        % No Waves with Constant Hydrodynamic Coefficients
                    obj.typeNum = 0;
                case {'noWaveCIC'}     % No Waves w/Convolution Integral Calculation
                    obj.typeNum = 1;
                case {'regular'}       % Regular Waves with Constant Hydrodynamic Coefficients
                    obj.typeNum = 10;
                case {'regularCIC'}    % Regular Waves w/Convolution Integral Calculation
                    obj.typeNum = 11;
                case 'irregular'       % Irregular Waves with 'PM' or 'JS' wave spectrum
                    obj.typeNum = 20;
                case 'spectrumImport' % Irregular waves with imported wave spectrum
                    obj.typeNum = 21;
                case 'etaImport'     % Waves with imported wave elevation time-history
                    obj.typeNum = 30;
            end
        end
        
        function plotEta(obj,rampTime)
            % This method plots wave elevation time-history.
            %
            % Parameters
            % ------------
            %     rampTime : float, optional
            %         Specify wave ramp time to include in plot    
            %
            % Returns
            % ------------
            %     figure : fig
            %         Plot of wave elevation versus time  
            %            
            figure
            plot(obj.waveAmpTime(:,1),obj.waveAmpTime(:,2))
            title('Wave Surfave Elevation')
            if nargin==2
                hold on
                line([rampTime,rampTime],[1.5*min(obj.waveAmpTime(:,2)),1.5*max(obj.waveAmpTime(:,2))],'Color','k')
                title(['Wave Surfave Elevation, Ramp Time ' num2str(rampTime) ' (s)'])
            end
            xlabel('Time (s)')
            ylabel('Eta (m)')
        end
        
        function plotSpectrum(obj)
            % This method plots the wave spectrum.
            %
            % Returns
            % ------------
            %     figure : fig
            %         Plot of wave spectrum versus wave frequency
            %                 
            m0 = trapz(obj.w,obj.S);
            HsTest = 4*sqrt(m0);
            [~,I] = max(abs(obj.S));
            wp = obj.w(I);
            TpTest = 2*pi/wp;
            
            figure
            plot(obj.w,obj.S,'s-')
            hold on
            line([wp,wp],[0,max(obj.S)],'Color','k')
            xlim([0 max(obj.w)])
            title([obj.spectrumType, ' Spectrum, T_p= ' num2str(TpTest) ' [s], '  'H_m_0= ' num2str(HsTest), ' [m]'])
            if obj.spectrumType == 'JS'
                title([obj.spectrumType, ' Spectrum, T_p= ' num2str(TpTest) ' [s], H_m_0= ' num2str(HsTest), ' [m], gamma = ' num2str(obj.gamma)])
            end
            xlabel('Frequency (rad/s)')
            ylabel('Spectrum (m^2-s/rad)');
        end
        
        function waveSetup(obj,bemFreq,wDepth,rampTime,dt,maxIt,g, rho, endTime)
            % This method calculates WEC-Sim's wave properties 
            % based on the specified wave type.
            %
            obj.bemFreq    = bemFreq;
            obj.setWaveProps(wDepth)
            switch obj.type
                case {'noWave','noWaveCIC'}                    
                    if isempty(obj.w)
                        obj.w = 2*pi/obj.T;
                    end
                    obj.waveNumber(g)
                    obj.A = obj.H/2;
                    obj.waveElevNowave(maxIt,dt);
                case {'regular','regularCIC'}
                    if isempty(obj.w)
                        obj.w = 2*pi/obj.T;
                    end
                    obj.A = obj.H/2;
                    obj.waveNumber(g)
                    obj.waveElevReg(rampTime, dt, maxIt);
                    obj.wavePowerReg(g,rho);
                case {'irregular','spectrumImport'}
                    WFQSt=min(bemFreq);
                    WFQEd=max(bemFreq);
                    if ~isempty(obj.freqRange)
                        if obj.freqRange(1) > WFQSt && obj.freqRange(1) > 0
                            WFQSt = obj.freqRange(1);
                        else
                            warning('Min frequency range outside BEM data, min frequency set to min BEM frequency')
                        end
                        if obj.freqRange(2) < WFQEd && obj.freqRange(2) > WFQSt
                            WFQEd = obj.freqRange(2);
                        else
                            warning('Max frequency range outside BEM data, max frequency set to max BEM frequency')
                        end
                    end
                    switch obj.freqDisc
                        case {'Traditional'}
                            if isempty(obj.numFreq)
                                obj.numFreq = 1000;
                            end
                            obj.w = (WFQSt:(WFQEd-WFQSt)/(obj.numFreq-1):WFQEd)';
                            obj.dw= ones(obj.numFreq,1).*(WFQEd-WFQSt)./(obj.numFreq-1);
                        case {'EqualEnergy'}
                            numFreq_interp = 500000;
                            obj.w = (WFQSt:(WFQEd-WFQSt)/numFreq_interp:WFQEd)';
                            obj.dw = mean(diff(obj.w));
                            if isempty(obj.numFreq)
                                obj.numFreq = 500;
                            end
                        case {'Imported'}
                            data = importdata(obj.spectrumDataFile);
                            freq_data = data(:,1);
                            freq_loc = freq_data>=min(obj.bemFreq)/2/pi & freq_data<=max(obj.bemFreq)/2/pi;
                            obj.w    = freq_data(freq_loc).*2.*pi;
                            obj.numFreq = length(obj.w);
                            obj.dw(1,1)= obj.w(2)-obj.w(1);
                            obj.dw(2:obj.numFreq-1,1)=(obj.w(3:end)-obj.w(1:end-2))/2;
                            obj.dw(obj.numFreq,1)= obj.w(end)-obj.w(end-1);
                    end
                    obj.setWavePhase;
                    obj.irregWaveSpectrum(g,rho)
                    obj.waveNumber(g)
                    obj.waveElevIrreg(rampTime, dt, maxIt, obj.dw);
                case {'etaImport'}    %  This does not account for wave direction
                    % Import 'etaImport' time-series here and interpolate
                    data = importdata(obj.etaDataFile) ;    % Import time-series
                    t = [0:dt:endTime]';      % WEC-Sim simulation time [s]
                    obj.waveElevUser(rampTime, dt, maxIt, data, t);
                    obj.waveAmpTime1        = zeros(maxIt+1,2);
                    obj.waveAmpTime1(:,1)   = [0:maxIt]*dt;
                    obj.waveAmpTime2        = zeros(maxIt+1,2);
                    obj.waveAmpTime2(:,1)   = [0:maxIt]*dt;
                    obj.waveAmpTime3        = zeros(maxIt+1,2);
                    obj.waveAmpTime3(:,1)   = [0:maxIt]*dt;
            end
        end
        
        function listInfo(obj)
            % This method prints wave information to the MATLAB Command
            % Window.
            %             
            fprintf('\nWave Environment: \n')
            switch obj.type
                case 'noWave'
                    fprintf('\tWave Type                            = No Wave (Constant Hydrodynamic Coefficients)\n')
                    fprintf('\tHydro Data Wave Period, T (sec)    	= %G\n',obj.T)
                case 'regular'
                    fprintf('\tWave Type                            = Regular Waves (Constant Hydrodynamic Coefficients)\n')
                    fprintf('\tWave Height, H (m)                   = %G\n',obj.H)
                    fprintf('\tWave Period, T (sec)                 = %G\n',obj.T)
                case 'noWaveCIC'
                    fprintf('\tWave Type                            = No Wave (Convolution Integral Calculation)\n')
                case 'regularCIC'
                    fprintf('\tWave Type                            = Regular Waves (Convolution Integral Calculation)\n')
                    fprintf('\tWave Height, H (m)                   = %G\n',obj.H)
                    fprintf('\tWave Period, T (sec)                 = %G\n',obj.T)
                case 'irregular'
                    if obj.phaseSeed == 0
                        fprintf('\tWave Type                            = Irregular Waves (Arbitrary Random Phase)\n')
                    else
                        fprintf('\tWave Type                            = Irregular Waves (Predefined Random Phase)\n')
                    end
                    obj.printWaveSpectrumType;
                    fprintf('\tSignificant Wave Height, Hs      (m) = %G\n',obj.H)
                    fprintf('\tPeak Wave Period, Tp           (sec) = %G\n',obj.T)
                case 'spectrumImport'
                    if size(importdata(obj.spectrumDataFile),2) == 3
                        fprintf('\tWave Type                            = Irregular waves with imported wave spectrum (Imported Phase)\n')
                    elseif obj.phaseSeed == 0
                        fprintf('\tWave Type                            = Irregular waves with imported wave spectrum (Random Phase)\n')
                    else
                        fprintf('\tWave Type                            = Irregular waves with imported wave spectrum (Seeded Phase)\n')
                    end
                    obj.printWaveSpectrumType;
                case 'etaImport'
                    fprintf( '\tWave Type                           = Waves with imported wave elevation time-history\n')
                    fprintf(['\tWave Elevation Time-Series File    	= ' obj.etaDataFile '  \n'])
            end
        end
        
        function waveNumber(obj,g)
            % This method calculates the wave number, 
            % used by: :meth:`waveClass.waveSetup`.
            % 
            obj.k = obj.w.^2./g;
            if obj.deepWaterWave == 0
                for i=1:100
                    obj.k = obj.w.^2./g./tanh(obj.k.*obj.waterDepth);
                end
            end
        end
        
        function checkinputs(obj)
            % This method checks WEC-Sim user inputs and generates error
            % messages if parameters are not properly defined. 

            % 'noWave' period undefined for hydro data
            if strcmp(obj.type,'noWave')
                if strcmp(obj.T,'NOT DEFINED')
                    error('"waves.T" must be defined for the hydrodynamic data period when using the "noWave" wave type');
                end
            end
            % spectrumDataFile defined for 'spectrumImport' case
            if strcmp(obj.type,'spectrumImport')
                if strcmp(obj.spectrumDataFile,'NOT DEFINED')
                    error('The "spectrumDataFile variable must be defined when using the "spectrumImport" wave type');
                end
            end
            % check waves types
            types = {'noWave', 'noWaveCIC', 'regular', 'regularCIC', 'irregular', 'spectrumImport', 'etaImport'};
            if sum(strcmp(types,obj.type)) ~= 1
                error(['Unexpected wave environment type setting, choose from: ' ...
                    '"noWave", "noWaveCIC", "regular", "regularCIC", "irregular", "spectrumImport", and "etaImport".'])
            end               
        end
        
        function write_paraview_vtp(obj, t, numPointsX, numPointsY, domainSize, model, simdate, mooring)
            % This methods writes vtp files for Paraview visualization.
            %
            
            % ground plane
            filename = ['vtk' filesep 'ground.txt'];
            fid = fopen(filename, 'w');
            fprintf(fid,[num2str(domainSize) '\n']);
            fprintf(fid,[num2str(obj.waterDepth) '\n']);
            fprintf(fid,[num2str(mooring) '\n']);
            fclose(fid);
            % wave
            x = linspace(-domainSize, domainSize, numPointsX);
            y = linspace(-domainSize, domainSize, numPointsY);
            [X,Y] = meshgrid(x,y);
            lx = length(x);
            ly = length(y);
            numVertex = lx * ly;
            numFace = (lx-1) * (ly-1);
            for it = 1:length(t)
                % open file
                filename = ['vtk' filesep 'waves' filesep 'waves_' num2str(it) '.vtp'];
                fid = fopen(filename, 'w');
                % calculate wave elevation
                Z = waveElevationGrid(obj, t(it), X, Y);
                % write header
                fprintf(fid, '<?xml version="1.0"?>\n');
                fprintf(fid, ['<!-- WEC-Sim Visualization using ParaView -->\n']);
                fprintf(fid, ['<!--   model: ' model ' - ran on ' simdate ' -->\n']);
                fprintf(fid, ['<!--   wave:  ' obj.type ' -->\n']);
                fprintf(fid, ['<!--   time:  ' num2str(t(it)) ' -->\n']);
                fprintf(fid, '<VTKFile type="PolyData" version="0.1">\n');
                fprintf(fid, '  <PolyData>\n');
                % write wave info
                fprintf(fid,['    <Piece NumberOfPoints="' num2str(numVertex) '" NumberOfPolys="' num2str(numFace) '">\n']);
                % write points
                fprintf(fid,'      <Points>\n');
                fprintf(fid,'        <DataArray type="Float32" NumberOfComponents="3" format="ascii">\n');
                for jj = 1:length(y)
                    for ii = 1:length(x)
                        pt = [X(jj,ii), Y(jj,ii), Z(jj,ii)];
                        fprintf(fid, '          %5.5f %5.5f %5.5f\n', pt);
                    end; clear ii
                    clear pt
                end; clear jj
                fprintf(fid,'        </DataArray>\n');
                fprintf(fid,'      </Points>\n');
                % write squares connectivity
                fprintf(fid,'      <Polys>\n');
                fprintf(fid,'        <DataArray type="Int32" Name="connectivity" format="ascii">\n');
                for jj = 1:ly-1
                    for ii = 1:lx-1
                        p1 = (jj-1)*lx + (ii-1);
                        p2 = p1+1;
                        p3 = p2 + lx;
                        p4 = p1 + lx;
                        fprintf(fid, '          %i %i %i %i\n', [p1,p2,p3,p4]);
                    end; clear ii
                end; clear jj
                fprintf(fid,'        </DataArray>\n');
                fprintf(fid,'        <DataArray type="Int32" Name="offsets" format="ascii">\n');
                fprintf(fid, '         ');
                for ii = 1:numFace
                    n = ii * 4;
                    fprintf(fid, ' %i', n);
                end; clear ii n
                fprintf(fid, '\n');
                fprintf(fid,'        </DataArray>\n');
                fprintf(fid, '      </Polys>\n');
                % end file
                fprintf(fid, '    </Piece>\n');
                fprintf(fid, '  </PolyData>\n');
                fprintf(fid, '</VTKFile>');
                % close file
                fclose(fid);
            end; clear it
            clear  numPoints numVertex numFace x y lx ly X Y Z fid filename p1 p2 p3 p4
        end
        
        function Z = waveElevationGrid(obj, t, X, Y)
            % This method calculates wave elevation on a grid at a given
            % time, used by: :meth:`waveClass.write_paraview_vtp`.
            %             
            % Parameters
            % ------------
            %     waves: obj
            %       waveClass object
            %
            %     t : float
            %       the current time
            %
            %     X : matrix
            %       (m x n) matrix of X coordinates at which to calculate the wave elevation
            %
            %     Y : matrix
            %       (m x n) matrix of Y coordinates at which to calculate the wave elevation
            %
            % Returns
            % ---------
            %     Z : matrix
            %       (m x n) matrix of Z coordinates of the wave elevation
            %
            switch obj.type                
                case {'noWave','noWaveCIC','etaImport'}                    
                    Z = zeros (size (X));                    
                case {'regular', 'regularCIC'}                    
                    Xt = X*cos (obj.waveDir*pi/180) + Y * sin(obj.waveDir*pi/180);                    
                    Z = obj.A * cos(-1 * obj.k * Xt  +  obj.w * t);                    
                case {'irregular', 'spectrumImport'}                    
                    Z = zeros (size (X));                    
                    Xt = X.*cos (obj.waveDir*pi/180) + Y.*sin (obj.waveDir*pi/180);                    
                    for iw = 1:length (obj.w)                        
                        Z = Z + sqrt (obj.A(iw)*obj.dw(iw)) * cos ( -1*obj.k(iw)*Xt + obj.w(iw)*t + obj.phase(iw) );                        
                    end                    
            end            
        end        
    end
    
    methods (Access = 'protected')
        function setWavePhase(obj)
            % Sets the irregular wave's random phase
            % Used by waveSetup
            if obj.phaseSeed ~= 0
                rng(obj.phaseSeed); % Phase seed = 1,2,3,...,etc
            else
                rng('shuffle');         % Phase seed shuffled
            end
            switch obj.freqDisc
                case {'EqualEnergy','Traditional'}
                    obj.phase = 2*pi*rand(length(obj.waveDir),obj.numFreq);
                case {'Imported'}
                    data = importdata(obj.spectrumDataFile);
                    if size(data,2) == 3
                        freq_data = data(:,1);
                        freq_loc = freq_data>=min(obj.bemFreq)/2/pi & freq_data<=max(obj.bemFreq)/2/pi;
                        phase_data = data(freq_loc,3);
                        obj.phase = phase_data';
                    else
                        obj.phase = 2*pi*rand(1,obj.numFreq);
                    end
            end
            obj.phase = obj.phase';
        end
        
        function setWaveProps(obj,wDepth)
            % Sets global and type-specific properties
            % Used by waveSetup
            if strcmp(wDepth,'infinite')
                obj.deepWaterWave = 1;
                obj.waterDepth = 200;
                fprintf('\tInfinite water depth specified in BEM, "waves.waterDepth" set to 200m for vizualisation.\n')
            else
                obj.deepWaterWave = 0;
                obj.waterDepth = double(wDepth);
            end
            switch obj.type
                case {'noWave'}
                    obj.H = 0;
                case {'noWaveCIC'}
                    obj.H = 0;
                    if isempty(obj.w) && strcmp(obj.T,'NOT DEFINED')
                        obj.w = min(obj.bemFreq);
                        obj.T=2*pi/obj.w;
                    elseif isempty(obj.w)
                        obj.w = 2*pi/obj.T;
                    else
                        obj.T = 2*pi/obj.w;
                    end
                case {'spectrumImport'}
                    obj.H = 0;
                    obj.T = 0;
                    obj.freqDisc = 'Imported';
                    obj.spectrumType = 'spectrumImport';
            end
        end
        
        function waveElevNowave(obj,maxIt,dt)
            % Set noWave levation time-history
            obj.waveAmpTime         = zeros(maxIt+1,2);
            obj.waveAmpTime(:,1)    = [0:maxIt]*dt;
            obj.waveAmpTime1        = zeros(maxIt+1,2);
            obj.waveAmpTime1(:,1)   = [0:maxIt]*dt;
            obj.waveAmpTime2        = zeros(maxIt+1,2);
            obj.waveAmpTime2(:,1)   = [0:maxIt]*dt;
            obj.waveAmpTime3        = zeros(maxIt+1,2);
            obj.waveAmpTime3(:,1)   = [0:maxIt]*dt;
        end
        
        function waveElevReg(obj, rampTime,dt,maxIt)
            % Calculate regular wave elevation time history
            % Used by waveSetup
            obj.waveAmpTime = zeros(maxIt+1,2);
            maxRampIT=round(rampTime/dt);
            if rampTime==0
                for i=1:maxIt+1
                    t = (i-1)*dt;
                    obj.waveAmpTime(i,1)    = t;
                    obj.waveAmpTime(i,2)    = obj.A*cos(obj.w*t);
                    obj.waveAmpTime1(i,1)   = t;
                    obj.waveAmpTime1(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge1loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge1loc(2).*sin(obj.waveDir*pi/180)));
                    obj.waveAmpTime2(i,1)   = t;
                    obj.waveAmpTime2(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge2loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge2loc(2).*sin(obj.waveDir*pi/180)));
                    obj.waveAmpTime3(i,1)   = t;
                    obj.waveAmpTime3(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge3loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge3loc(2).*sin(obj.waveDir*pi/180)));
                end
            else
                for i=1:maxRampIT
                    t = (i-1)*dt;
                    obj.waveAmpTime(i,1)    = t;
                    obj.waveAmpTime(i,2)    = obj.A*cos(obj.w*t)*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                    obj.waveAmpTime1(i,1)   = t;
                    obj.waveAmpTime1(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge1loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge1loc(2).*sin(obj.waveDir*pi/180)))*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                    obj.waveAmpTime2(i,1)   = t;
                    obj.waveAmpTime2(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge2loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge2loc(2).*sin(obj.waveDir*pi/180)))*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                    obj.waveAmpTime3(i,1)   = t;
                    obj.waveAmpTime3(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge3loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge3loc(2).*sin(obj.waveDir*pi/180)))*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                end
                for i=maxRampIT+1:maxIt+1
                    t = (i-1)*dt;
                    obj.waveAmpTime(i,1)    = t;
                    obj.waveAmpTime(i,2)    = obj.A*cos(obj.w*t);
                    obj.waveAmpTime1(i,1)   = t;
                    obj.waveAmpTime1(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge1loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge1loc(2).*sin(obj.waveDir*pi/180)));
                    obj.waveAmpTime2(i,1)   = t;
                    obj.waveAmpTime2(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge2loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge2loc(2).*sin(obj.waveDir*pi/180)));
                    obj.waveAmpTime3(i,1)   = t;
                    obj.waveAmpTime3(i,2)   = obj.A*cos(obj.w*t-obj.k*(obj.wavegauge3loc(1).*cos(obj.waveDir*pi/180) + obj.wavegauge3loc(2).*sin(obj.waveDir*pi/180)));
                end
            end
        end
        
        function wavePowerReg(obj,g,rho)
            % Calculate wave power per unit wave crest for regular waves
            if obj.deepWaterWave == 1
                % Deepwater Approximation
                obj.Pw = 1/(8*pi)*rho*g^(2)*(obj.A).^(2).*obj.T;               
            else
                % Full Wave Power Equation
                obj.Pw = rho*g*(obj.A).^(2)/4*sqrt(g./obj.k.*tanh(obj.k.*obj.waterDepth))*(1+2*obj.k.*obj.waterDepth./sinh(obj.k.*obj.waterDepth));
            end
        end
        
        function irregWaveSpectrum(obj,g,rho)
            % Calculate wave spectrum vector (obj.A)
            % Used by wavesIrreg (wavesIrreg used by waveSetup)
            freq = obj.w/(2*pi);
            Tp = obj.T;
            Hs = obj.H;
            switch obj.spectrumType
                case {'PM','JS'} 
                    % Pierson-Moskowitz Spectrum from IEC TS 62600-2 ED2 Annex C.2 (2019)
                    B_PM = (5/4)*(1/Tp)^(4);
                    A_PM =  B_PM*(Hs/2)^2;
                    S_f  = (A_PM*freq.^(-5).*exp(-B_PM*freq.^(-4)));            % Wave Spectrum [m^2-s] for 'EqualEnergy'
                    if strcmp(obj.spectrumType,'JS')
                        % JONSWAP Spectrum from IEC TS 62600-2 ED2 Annex C.2 (2019)
                        fp = 1/Tp;
                        siga = 0.07;sigb = 0.09;                                    % cutoff frequencies for gamma function
                        [lind,~] = find(freq<=fp);
                        [hind,~] = find(freq>fp);
                        gammaAlpha = zeros(size(freq));
                        if isempty(obj.gamma)
                            TpsqrtHs = Tp/sqrt(Hs);
                            if TpsqrtHs <= 3.6
                                obj.gamma = 5;
                            elseif TpsqrtHs > 5
                                obj.gamma = 1;
                            else
                                obj.gamma = exp(5.75 - 1.15*TpsqrtHs);
                            end
                        end
                        gammaAlpha(lind) = obj.gamma.^exp(-(freq(lind)-fp).^2/(2*siga^2*fp^2));
                        gammaAlpha(hind) = obj.gamma.^exp(-(freq(hind)-fp).^2/(2*sigb^2*fp^2));
                        C = 1 - 0.287*log(obj.gamma);
                        S_f = C*S_f.*gammaAlpha;                                % Wave Spectrum [m^2-s]
                    end
                    obj.S = S_f./(2*pi);                                       % Wave Spectrum [m^2-s/rad]
                case 'spectrumImport' % Imported Wave Spectrum
                    data = importdata(obj.spectrumDataFile);
                    freq_data = data(:,1);
                    S_data = data(:,2);
                    freq_loc = freq_data>=min(obj.bemFreq)/2/pi & freq_data<=max(obj.bemFreq)/2/pi;
                    S_f = S_data(freq_loc);                                    % Wave Spectrum [m^2-s] for 'EqualEnergy'
                    obj.S = S_f./(2*pi);                                       % Wave Spectrum [m^2-s/rad] for 'Traditional'
                    fprintf('\t"spectrumImport" uses the number of imported wave frequencies (not "Traditional" or "EqualEnergy")\n')
                case {'BS'} 
                    error('Bretschneider Sprectrum ("BS" option) is no longer supported');
            end
            % Power per Unit Wave Crest
            obj.waveNumber(g)                                                   %Calculate Wave Number for Larger Number of Frequencies Before Down Sampling in Equal Energy Method
            if obj.deepWaterWave == 1
                % Deepwater Approximation
                obj.Pw = sum(1/2*rho*g^(2)*S_f.*obj.dw./obj.w);
            else
                % Full Wave Power Equation
                obj.Pw = sum((1/2)*rho*g.*S_f.*obj.dw.*sqrt(9.81./obj.k.*tanh(obj.k.*obj.waterDepth)).*(1 + 2.*obj.k.*obj.waterDepth./sinh(2.*obj.k.*obj.waterDepth)));
            end
            %
            switch obj.freqDisc
                case {'EqualEnergy'}
                    m0 = trapz(freq,abs(S_f));
                    numBins = obj.numFreq+1;
                    a_targ = m0/(numBins);
                    SF = cumtrapz(freq,S_f);
                    wn(1) = 1;
                    for kk = 1:numBins
                        jj = 1;
                        tmpa{kk}(1) = 0;
                        while tmpa{kk}(jj)-kk*a_targ < 0
                            tmpa{kk}(jj+1) = SF(wn(kk)+jj);
                            jj = jj+1;
                            if wn(kk)+jj >=length(S_f)
                                break
                            end
                        end
                        [a_targ_real(kk),wna(kk)] = min(abs(tmpa{kk}-kk*a_targ));
                        wn(kk+1) = wna(kk)+wn(kk);
                        a_bins(kk) = trapz(freq(wn(kk):wn(kk+1)),abs(S_f(wn(kk):wn(kk+1))));
                    end
                    obj.w = 2*pi*freq(wn(2:end-1));
                    obj.dw = [obj.w(1)-2*pi*freq(wn(1)); diff(obj.w)];
                    obj.S = obj.S(wn(2:end-1));                             % Wave Spectrum [m^2-s/rad] 
            end
            obj.A = 2 * obj.S;                                              % Wave Amplitude [m]
        end
        
        function waveElevIrreg(obj,rampTime,dt,maxIt,df)
            % Calculate irregular wave elevetaion time history
            % Used by waveSetup
            obj.waveAmpTime = zeros(maxIt+1,2);
            obj.waveAmpTime1 = zeros(maxIt+1,2);
            obj.waveAmpTime2 = zeros(maxIt+1,2);
            obj.waveAmpTime3 = zeros(maxIt+1,2);
            maxRampIT=round(rampTime/dt);
            if rampTime==0
                for i=1:maxIt+1
                    for idir=1:length(obj.waveDir)
                        t       = (i-1)*dt;
                        tmp     = sqrt(obj.A.*df*obj.waveSpread(idir));
                        tmp1    = tmp.*real(exp(sqrt(-1).*(obj.w.*t + obj.phase(:,idir))));
                        tmp11   = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge1loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge1loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        tmp12   = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge2loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge2loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        tmp13   = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge3loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge3loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        obj.waveAmpTime(i,1)    = t;
                        obj.waveAmpTime(i,2)    = obj.waveAmpTime(i,2) + sum(tmp1);
                        obj.waveAmpTime1(i,1)   = t;
                        obj.waveAmpTime1(i,2)   = obj.waveAmpTime1(i,2) + sum(tmp11);
                        obj.waveAmpTime2(i,1)   = t;
                        obj.waveAmpTime2(i,2)   = obj.waveAmpTime2(i,2) + sum(tmp12);
                        obj.waveAmpTime3(i,1)   = t;
                        obj.waveAmpTime3(i,2)   = obj.waveAmpTime3(i,2) + sum(tmp13);
                    end
                end
            else
                for i=1:maxRampIT
                    for idir=1:length(obj.waveDir)
                        t = (i-1)*dt;
                        tmp=sqrt(obj.A.*df*obj.waveSpread(idir));
                        tmp1    = tmp.*real(exp(sqrt(-1).*(obj.w.*t + obj.phase(:,idir))));
                        tmp11   = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge1loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge1loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        tmp12   = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge2loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge2loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        tmp13   = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge3loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge3loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        obj.waveAmpTime(i,1)    = t;
                        obj.waveAmpTime(i,2)    = obj.waveAmpTime(i,2) + sum(tmp1)*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                        obj.waveAmpTime1(i,1)   = t;
                        obj.waveAmpTime1(i,2)   = obj.waveAmpTime1(i,2) + sum(tmp11)*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                        obj.waveAmpTime2(i,1)   = t;
                        obj.waveAmpTime2(i,2)   = obj.waveAmpTime2(i,2) + sum(tmp12)*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                        obj.waveAmpTime3(i,1)   = t;
                        obj.waveAmpTime3(i,2)   = obj.waveAmpTime3(i,2) + sum(tmp13)*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                    end
                end
                for i=maxRampIT+1:maxIt+1
                    for idir=1:length(obj.waveDir)
                        t = (i-1)*dt;
                        tmp=sqrt(obj.A.*df*obj.waveSpread(idir));
                        tmp1  = tmp.*real(exp(sqrt(-1).*(obj.w.*t + obj.phase(:,idir))));
                        tmp11 = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge1loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge1loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        tmp12 = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge2loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge2loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        tmp13 = tmp.*real(exp(sqrt(-1).*(obj.w.*t - obj.k*(obj.wavegauge3loc(1).*cos(obj.waveDir(idir)*pi/180) + obj.wavegauge3loc(2).*sin(obj.waveDir(idir)*pi/180)) + obj.phase(:,idir))));
                        obj.waveAmpTime(i,1)    = t;
                        obj.waveAmpTime(i,2)    = obj.waveAmpTime(i,2) + sum(tmp1);
                        obj.waveAmpTime1(i,1)   = t;
                        obj.waveAmpTime1(i,2)   = obj.waveAmpTime1(i,2) + sum(tmp11);
                        obj.waveAmpTime2(i,1)   = t;
                        obj.waveAmpTime2(i,2)   = obj.waveAmpTime2(i,2) + sum(tmp12);
                        obj.waveAmpTime3(i,1)   = t;
                        obj.waveAmpTime3(i,2)   = obj.waveAmpTime3(i,2) + sum(tmp13);
                    end
                end
            end
        end
        
        function waveElevUser(obj,rampTime,dt,maxIt,data, t)
            % Calculate imported wave elevation time history
            % Used by waveSetup
            obj.waveAmpTime = zeros(maxIt+1,2);
            maxRampIT=round(rampTime/dt);
            data_t = data(:,1)';                    % Data Time [s]
            data_x = data(:,2)';                    % Wave Surface Elevation [m]
            obj.waveAmpTime(:,1) = t;
            obj.waveAmpTime(:,2) = interp1(data_t,data_x,t);
            if rampTime~=0
                for i=1:maxRampIT
                    obj.waveAmpTime(i,2) = obj.waveAmpTime(i,2)*(1+cos(pi+pi*(i-1)/maxRampIT))/2;
                end
            end
        end
        
        function printWaveSpectrumType(obj)
            % Lists the wave spectrum type
            % Used by listInfo
            if strcmp(obj.spectrumType,'JS')
                fprintf('\tSpectrum Type                        = JONSWAP \n')
            elseif strcmp(obj.spectrumType,'PM')
                fprintf('\tSpectrum Type                        = Pierson-Moskowitz  \n')
            elseif strcmp(obj.spectrumType,'spectrumImport')
                fprintf('\tSpectrum Type                        = Imported Spectrum \n')
            end
        end
    end
end
