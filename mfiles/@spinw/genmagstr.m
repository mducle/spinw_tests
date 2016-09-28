function genmagstr(obj, varargin)
% generates magnetic structure
%
% GENMAGSTR(obj, 'option1', value1 ...)
%
% There are several ways to generate magnetic structure. The selected
% method depends on the 'mode' option, see below. The magnetic structure is
% stored in the obj.mag_str field. The default mode is 'extend'. The
% magetic structure is stored as Fourier components with arbitrary number
% of wave vectors in the spinw object. However spin waves can be only
% calculated if the magnetic structure has only a single propagation vector
% (plus a k=0 ferromagnetic component) we simply call it single-k magnetic
% structure. Thus genmagstr() enables to input magnetic structures that
% comply with this restriction by defining a magnetic structure by the
% moment directions (S) in the crystallographic cell, a propagation vector
% (km) and a vector that defines the normal of the rotation of the spin
% spiral (n). The function converts these values into Fourier components to
% store. To solve spin wave dispersion of magnetic structures with multiple
% propagation vectors, a magnetic supercell has to be defined where the
% propagation vector can be approximated to zero.
%
% Input:
%
% obj       spinw class object.
%
% Options:
%
% mode       Mode how the magnetic structure is generated:
%
%            'random'
%                   generates random zero-k magnetic structure.
%
%            'direct'
%                   direct input of the magnetic structure using the 
%                   parameters of the single-k magnetic structure.
%
%            'tile' (default)
%                   Simply extends the existing or input structure
%                   (param.S) into a magnetic supercell by replicating it.
%                   If no structure is stored in the spinw object a random
%                   structure is generated automatically. If defined,
%                   param.S is used as starting structure for extension
%                   overwriting the stored structure. If the original
%                   structure is already extended with other size, only the
%                   moments in the crystallographic cell wil be replicated.
%                   Magnetic ordering wavevector k will be set to zero. To
%                   generate structure with non-zero k, use 'helical' or
%                   'direct' option.
%
%            'helical'
%                   generates helical structure in a single cell or in a
%                   supercell. In contrary to the 'extend' option the
%                   magnetic structure is not generated by replication but
%                   by rotation of the moments using the following formula:
%
%                       S_gen_i(r) = ROT(2*pi*km*r)*S_i.
%
%                   where S_i has either a single moment or as many moments
%                   as the number of magnetic atoms in the crystallographic
%                   cell. In the first case 'r' denotes the atomic
%                   positions, while for the second case 'r' denotes the
%                   position of the origin of the cell.
%
%            'rotate'
%                   uniform rotation of all magnetic moments with a
%                   param.phi angle around the param.n vector. If
%                   param.phi=0, all moments are rotated so, that the first
%                   moment is parallel to param.n vector in case of
%                   collinear structure or in case of planar structure
%                   param.n defines the normal of the plane of the magnetic
%                   moments.
%
%            'func'
%                   function that defines the parameters of the single-k
%                   magnetic structure: moment vectors, propagation vector
%                   and normal vector from arbitrary parameters in the
%                   following form:
%
%                       [S, k, n] = @(x)func(S0, x)
%
%                   where S is matrix with dimensions of [3 nMagExt]. k is
%                   the propagation vector, its dimension is [1 3]. n is
%                   the normal vector of the spin rotation plane, its
%                   dimension is [1 3]. The default function is
%                   @gm_spherical3d. For planar magnetic structure use
%                   @gm_planar. Only param.func and param.x have to be
%                   defined for this mode.
%
%            'fourier'
%                   store general magnetic structure by the given Fourier
%                   components. The moments for a magnetic supercellare
%                   defined using the following equation:
%
%                       F(l,j,k) = F(j,k)*exp(-i*k*l)
%
%                   Where F(l,j,k) is the generated k-Fourier component on
%                   the l-th unit cell, j-th atom. The size of the
%                   generated supercell is determined by the 'nExt' option.
%                   The 'Fk' option gives the Furier components and the
%                   k-vectors in a cell in the following structure: {Fk1 k1
%                   Fk2 k2 ...} The Fk1, Fk2 etc are complex matrices that
%                   contain the Fourier compoents on every magnetic atom in
%                   the crystallographic cell. They have a dimension of [3
%                   nMagAtom]. The k1, k2 etc are k-vectors of the Fourier
%                   componets, with dimensions of [1 3]. Since the
%                   generated magnetic structures have to be real, the -k
%                   componets are automatically added: F(-k) = conj(F(k)).
%                   Example input: {[1 -1;i1 -i1;0 0] [1/2 0 0] [1 -1;0 0;
%                   i1 -i1] [0 1/2 0]} This gives a double k structure for
%                   a lattice with two magnetic atoms in the unit cell. The
%                   Fourier componets are by default in the xyz coordinate
%                   system but if param.unitS is set to 'lu', than the
%                   moment components are assumed to be in lattice units.
%
% phi       Angle of rotation of the magnetic moments in rad. Default
%           value is 0.
% phid      Angle of rotation of the magnetic moments in degree. Default
%           value is 0.
% nExt      Size of the magnetic supercell in multiples of the
%           crystallographic cell, dimensions are [1 3]. Default value is
%           stored in obj. If nExt is a single number, then the size of the
%           extended unit cell is automatically determined from the FIRST
%           magnetic ordering wavevector. If nExt = 0.01, then the number
%           of unit cells is determined so, that in the extended unit cell,
%           the magnetic ordering wave vector is [0 0 0], within the given
%           0.01 r.l.u. error.
% k         Magnetic ordering wavevector in r.l.u., dimensions are [nK 3].
%           Default value is defined in obj.
% n         Normal vector to the spin rotation plane for single-k magnetic
%           structures, dimensions are [1 3]. Default value [0 0 1].
% S         Direct input of the spin values, dimensions are [3 nSpin nK].
%           Every column defines the three (S_x, S_y, S_z) components of
%           the moment in the xyz Descartes coodinate system or in l.u.
%           coordinate system. Default value is stored in obj.
% unitS     Units for S and Fk, default is 'xyz', optionally 'lu' can be used,
%           in this case the input spin components are assumed to be in
%           lattice units and they will be converted to the xyz coordinate
%           system. Lattice units are determined by components along the
%           three lattice vector (length normalized to unity).
% epsilon   The smalles value of incommensurability that is
%           tolerated without warning in lattice units. Default is 1e-5.
% func      Function that produce the magnetic moments, ordering wave
%           vector and normal vector from the param.x parameters in the
%           following form:
%
%             [M, k, n] = @(x)func(M0,x)
%
%           where M is (3,nMagExt) size matrix, k is the propagation vector
%           with dimensions of [1 3], n is the normal vector of the spin
%           rotation plane, its dimensions are [1 3]. The default function
%           is @gm_spherical3d. For planar magnetic structure use
%           @gm_planar.
% x0        Input parameters for param.func function, dimensions are
%           [1 nx].
% norm      Set the length of the generated magnetic moments to be equal to
%           the spin of the magnetic atoms. Default is true.
% r0        If true and only a single spin direction is given, the spin
%           phases are determined by atomic position times k-vector, while
%           if it is false, the first spin will have zero phase. Default is
%           true.
%
% Output:
%
% The obj.mag_str field will contain the new magnetic structure using
% Fourier components.
%
% Example:
%
% USb = spinw;
% USb.genlattice('lat_const',[6.203 6.203 6.203],'angled',[90 90 90],'spgr','F m -3 m')
% USb.addatom('r',[0 0 0],'S',1)
% FQ = {[0;0;1+1i] [0 0 1] [0;1+1i;0] [0 1 0] [1+1i;0;0] [1 0 0]};
% USb.genmagstr('mode','fourier','Fk',FQ,'nExt',[1 1 1])
% plot(USb,'range',[1 1 1])
%
% The above example creates the multi-q magnetic structure of USb with the
% FQ Fourier components and plots the magnetic structure.
%
% See also SPINW, SPINW.ANNEAL, SPINW.OPTMAGSTR, GM_SPHERICAL3D, GM_PLANAR.
%

if isempty(obj.matom.r)
    error('spinw:genmagstr:NoMagAtom','There are no magnetic atoms (S>0) in the unit cell!')
end

inpForm.fname  = {'mode'   'nExt'            'k'           'n'   };
inpForm.defval = {'tile' obj.mag_str.nExt obj.mag_str.k' []    };
inpForm.size   = {[1 -1]   [1 -4]            [-6 3]        [-6 3] };
inpForm.soft   = {false    false             false         true  };

inpForm.fname  = [inpForm.fname  {'func'          'x0'   'norm' 'r0' }];
inpForm.defval = [inpForm.defval {@gm_spherical3d []     true   true }];
inpForm.size   = [inpForm.size   {[1 1]           [1 -3] [1 1]  [1 1]}];
inpForm.soft   = [inpForm.soft   {false           true   false  false}];

inpForm.fname  = [inpForm.fname  {'S'       'phi' 'phid' 'epsilon' 'unitS'}];
inpForm.defval = [inpForm.defval {[]         0     0      1e-5      'xyz'  }];
inpForm.size   = [inpForm.size   {[3 -7 -6] [1 1] [1 1]  [1 1]     [1 -5] }];
inpForm.soft   = [inpForm.soft   {true      true  false  false     false  }];

param = sw_readparam(inpForm, varargin{:});

if strcmp(param.mode,'extend')
    param.mode = 'tile';
end

% input type for S, check whether it is complex type
cmplxS = ~isreal(param.S);

if isempty(param.S)
    % use the complex Fourier components from the stored magnetic structure
    param.S = obj.mag_str.F;
    cmplxS  = true;
else
    switch lower(param.unitS)
        case 'lu'
            % convert the moments from lattice units to xyz
            BV = obj.basisvector(true);
            %param.S = BV*param.S;
            param.S = mmat(BV,param.S);
            
        case 'xyz'
            % do nothing
        otherwise
            error('spinw:genmagstr:WrongInput','Parameter unitS has to be either ''xyz'' or ''lu''!');
    end
end

% Magnetic ordering wavevector(s)
k  = param.k;
% number of k-vectors
nK = size(k,1);

nExt = double(param.nExt);

% automatic determination of the size of the extended unit cell based on
% the given k-vectors if nExt is a single number
if numel(nExt) == 1
    [~, nExtT] = rat(param.k(1,:),nExt);
    if nK>1
        for ii = 2:nK
            [~, nExtT2] = rat(param.k(ii,:),nExt);
            nExtT = lcm(nExtT,nExtT2);
        end
    end
    nExt = nExtT;
end

mAtom    = obj.matom;
nMagAtom = size(mAtom.r,2);
% number of magnetic atoms in the supercell
nMagExt  = nMagAtom*prod(nExt);

if nMagAtom==0
    error('sw:genmagstr:NoMagAtom','There is no magnetic atom in the unit cell with S>0!');
end

% Create mAtom.Sext matrix.
mAtom    = sw_extendlattice(nExt, mAtom);

% normalized axis of rotation, size (nK,3)
if isempty(param.n)
    % default value
    param.n = repmat([0 0 1],[nK 1]);
end
n = bsxfun(@rdivide,param.n,sqrt(sum(param.n.^2,2)));

if size(param.n,1) ~= nK
    error('spinw:genmagstr:WrongInput',['The number of normal vectors has'...
        ' to be equal to the number of k-vectors!'])
end

% if the magnetic structure is not initialized start with a random real one
if strcmp(param.mode,'tile') && (nMagAtom > size(param.S,2))
    param.mode = 'random';
end

% convert input into symbolic variables
if obj.symb
    k       = sym(k);
    param.S = sym(param.S);
    n       = sym(n);
end

if ~cmplxS
    param.S = param.S + 1i*cross(repmat(permute(n,[2 3 1]),[1 size(param.S,2) 1]),param.S);
end

switch param.mode
    case 'tile'
        % effectively tiles the magnetic supercell with the given magnetic
        % moments if:
        % -the new number of extended cells does not equal to the number of
        %  cells defined in obj
        % -the number of spins stored in obj is not equal to the number
        %  of spins in the final structure
        if any(obj.mag_str.N_ext - int32(param.nExt)) || (size(param.S,2) ~= nMagExt)
            S = param.S(:,1:nMagAtom,:);
            S = repmat(S,[1 prod(nExt) 1]);
        else
            S = param.S;
        end
        % sum up all kvectors and keep the real part only
        S  = real(sum(S,3));
        k = [0 0 0];
        
    case 'random'
        % Create random spin directions and use a single k-vector
        S  = randn(nMagExt,3);
        S  = bsxfun(@rdivide,S,sqrt(sum(S.^2,2)));
        S  = bsxfunsym(@times,S,mAtom.Sext')';
        k  = [0 0 0];
        
    case 'helical'
        S0 = param.S;
        % Magnetic ordering wavevector in the extended unit cell.
        kExt = k.*nExt;
        % Warns about the non sufficient extension of the unit cell.
        % we substitute random values for symbolic km
        skExt = sw_sub1(kExt,'rand');
        if any(abs(skExt-round(skExt))>param.epsilon) && prod(nExt) > 1
            warning('sw:genmagstr:UCExtNonSuff','In the extended unit cell k is still larger than epsilon!');
        end
        % number of spins in the input
        nSpin = size(param.S,2);
        
        if (nSpin~= nMagAtom) && (nSpin==1)
            % there is only a single given spin, use the fractional atomic position
            if param.r0
                r = mAtom.RRext;
            else
                r = bsxfun(@minus,mAtom.RRext,mAtom.RRext(:,1));
            end
        elseif nSpin == nMagAtom
            % moments in the crystallographic unit cell are defined, use
            % only unit cell position.
            r = bsxfun(@rdivide,floor(bsxfun(@times,mAtom.RRext,nExt')),nExt');
        else
            error('sw:genmagstr:WrongNumberSpin','Wrong number of input spins!');
        end
                
        % additional phase for eahc spin in the magnetic supercell
        phi = sum(bsxfun(@times,2*pi*kExt',r),1);

        % add the extra phase for each spin in the unit cell
        % TODO check
        S = bsxfun(@times,S0(:,mod(0:(nMagExt-1),nSpin)+1,:),exp(-1i*phi));
        
    case 'direct'
        % direct input of real magnetic moments
        S = param.S;
        if size(S,2) == nMagAtom
            % single unit cell
            nExt = [1 1 1];
        end
        
        if size(S,2) ~= nMagExt
            error('sw:genmagstr:WrongSpinSize','Wrong size of param.S!');
        end
                
    case 'rotate'
        
        if param.phi == 0
            % use degrees for phi if given
            param.phi = param.phid*pi/180;
        end
        
        S   = param.S;
        
        if ~isreal(param.phi)
            % rotate the first spin along [100]
            S1 = S(:,1)-sum(n*S(:,1))*n';
            S1 = S1/norm(S1);
            param.phi = -atan2(cross(n,[1 0 0])*S1,[1 0 0]*S1);
        end

        if param.phi == 0
            % The starting vector, size (1,3):
            incomm = mod(bsxfun(@times,k,nExt),1);
            incomm = any(incomm(:));
            if incomm
                S1 = sw_nvect(S);
            else
                S1 = sw_nvect(real(S));
            end
            
            % Axis of rotation defined by the spin direction
            nRot  = cross(n,S1);
            % Angle of rotation.
            phi = -atan2(norm(cross(S1,n)),dot(S1,n));
        else
            nRot = n;
            % Angle of rotation.
            phi = param.phi(1);
        end
        % Rotate the spins.
        S = sw_rot(nRot,phi,S);
        k = obj.mag_str.k';
        
    case 'func'
        S = mAtom.S;
        S = repmat(S,[prod(nExt) 1]);
        
        if obj.symbolic
            [S, k, ~] = param.func(sym(S), sym(param.x0));
        else
            [S, k, ~] = param.func(S,param.x0);
        end
%     case 'fourier'
%         % generate supercell from Fourier components
%         % keeps the final k-vector zero
%         Fk = param.Fk;
%         if isempty(Fk) || ~iscell(Fk)
%             error('spinw:genmagstr:WrongInput','Wrong ''Fk'' option that defines the Fourier components!');
%         end
%         
%         % number of moments for the Fourier components are defined
%         nFourier = size(Fk{1},2);
%         nQ = numel(Fk)/2;
%         
%         if (nFourier ~= nMagAtom) && (nFourier==1)
%             % Single defined moment, use the atomic position in l.u.
%             RR = bsxfun(@times,mAtom.RRext,nExt');
%         elseif nFourier == nMagAtom
%             % First crystallographic unit cell defined, use only unit cell
%             % position in l.u.
%             RR = floor(bsxfun(@times,mAtom.RRext,nExt'));
%         else
%             error('sw:genmagstr:WrongNumberComponent','Wrong number of input Fourier components!');
%         end
%         
%         % no moments
%         S = RR*0;
%         % number of cells in the supercell
%         nCell = prod(nExt);
%         
%         % save the Fourier components
%         S = cat(3,Fk{1:2:end});
%         k = cat(1,Fk{2:2:end})';
%         
%         % multiply the Fourier components with the spin quantum number
%         % TODO
%         
%         
% %         for ii = 1:2:(2*nQ)
% %             % F(k)
% %             S = S + bsxfunsym(@times,repmat(Fk{ii},[1 nCell*nMagAtom/nFourier]),exp(1i*Fk{ii+1}*RR*2*pi))/2;
% %             % conj(F(k))
% %             S = S + bsxfunsym(@times,repmat(conj(Fk{ii}),[1 nCell*nMagAtom/nFourier]),exp(-1i*Fk{ii+1}*RR*2*pi))/2;
% %             
% %         end
% %         S = real(S);
% % 
% %         k = [0 0 0];
% %         
%         warning('spinw:genmagstr:Approximation',['The generated magnetic '...
%             'structure is only an approximation of the input multi-q'...
%             ' structure on a supercell!'])
%         %n = [0 0 1];
%         
    otherwise
        error('spinw:genmagstr:WrongMode','Wrong param.mode value!');
end

% normalize the magnetic moments
if param.norm
    normS = sqrt(sum(real(S).^2,1))./repmat(mAtom.S,[1 prod(nExt)]);
    normS(normS==0) = 1;
    S = bsxfunsym(@rdivide,S,normS);
end

% simplify expressions
if obj.symbolic
    S = simplify(sym(S));
    k = simplify(sym(k));
end

mag_str.nExt = int32(nExt(:))';
mag_str.k    = k';
mag_str.F    = S;

obj.mag_str   = mag_str;
validate(obj);

end