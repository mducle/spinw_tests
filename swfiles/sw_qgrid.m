function qGrid = sw_qgrid(varargin)
% creates a Q grid
%
% qGrid = SW_QGRID('option1',value1,...)
%
% The function helps to generate n-dimensional grids (n<=3) in 3D space. It
% uses n linearly independent vectors ("lattice vectors") and bin values
% (coordinates in "lattice units" or "lu") to generate the points. It works
% similarly as the d3d constructor in Horace.
%
% Options:
%
% u         Row vector with 3 elements, determining the first axis in 3D
%           space, default value is [1 0 0].
% v         Second axis, default value is [0 1 0].
% w         Third axis, default value is [0 0 1].
% uoffset   Column vector with 3 elements, determining the offset of origin
%           in lu, (fourth element is accepted but discarded).
% ubin      Bin points along the first axis. Can be a vector with 1, 2 or 3
%           elements:
%               [B1]        single value along the u-axis:  B1*u
%               [B1 B2]     range along the u-axis:         [B1:1/nExt:B2]*u
%               [B1 dB B2]  range along the u-axis:         [B1:dB:B2]*u
% vbin      Same as ubin but along the v-axis.
% wbin      Same as ubin but along the w-axis.
% nExt      Vector with n-elements that can define fractional bin steps,
%           default is [1 1 1].
% lab       Cell array of projection axis labels with 3 elements (4th
%           element discarded).
%
% n is determined by the number of given bins (1<=n<=3), so if only 'ubin'
% is given, n=1; if 'ubin' and 'vbin' are both given n=2, etc.
%
% Output:
%
% qGrid     A matrix with dimensions of [3,nAx1,nAx2,...], where nAxi is
%           the index of points along axis i with 1<=i<=n.
%
% See also SW_QSCAN.
%

inpForm.fname  = {'u'     'v'     'w'     'uoffset' 'lab'                          };
inpForm.defval = {[1 0 0] [0 1 0] [0 0 1] [0 0 0]   {'(h,0,0)' '(0,k,0)' '(0,0,l)'}};
inpForm.size   = {[1 3]   [1 3]   [1 3]   [1 -1]    [1 -2]                         };
inpForm.soft   = {false   false   false   false     false                          };

inpForm.fname  = [inpForm.fname  {'ubin' 'vbin' 'wbin' 'nExt'  'mat'  'bin' }];
inpForm.defval = [inpForm.defval { []     []     []    [1 1 1] []     {}    }];
inpForm.size   = [inpForm.size   {[1 -3] [1 -4] [1 -5] [1 -6]  [-7 3] [1 -8]}];
inpForm.soft   = [inpForm.soft   {true   true   true   false   true   true  }];

param = sw_readparam(inpForm, varargin{:});

if nargin == 0
    help sw_qgrid
    return
end

% size of magnetic supercell
nExt = double(param.nExt);

% create bin vectors
if isempty(param.bin)
    bin  = {param.ubin param.vbin param.wbin};
    ebin = cellfun(@(C)~isempty(C),bin);
    if ~ismember(double(ebin),[1 0 0;1 1 0;1 1 1],'rows')
        error('sw_qgrid:WrongInput','Wrong input!')
    end
    % number of dimensions
    nDim = sum(ebin);

else
    nDim = numel(param.bin);
    bin  = param.bin; 
end

v   = cell(1,nDim);

for ii = 1:nDim
    bin0 = bin{ii};
    switch numel(bin0)
        case 1
            v{ii} = bin0;
        case 2
            v{ii} = bin0(1):(1/nExt(ii)):bin0(2);
        case 3
            v{ii} = bin0(1):bin0(2):bin0(3);
        otherwise
            if isempty(param.bin)
                error('sw_qgrid:WrongInput','Each bin has to be 1, 2 or 3 element vector!')
            end
            v{ii} = bin0;
    end
end

% create bin vector grid
vTemp = cell(1,nDim);
[vTemp{:}] = ndgrid(v{:});
vv = cat(nDim+1,vTemp{:});
% axis matrix, each column is an axis vector
if isempty(param.mat)
    axMat = [param.u;param.v;param.w]';
else
    axMat = param.mat;
end
axMat = axMat(:,1:nDim);

% create Q matrix
qGrid = sum(bsxfun(@times,permute(axMat,[1 (3:nDim+2) 2]),permute(vv,[nDim+2 (1:nDim+1)])),nDim+2);

end