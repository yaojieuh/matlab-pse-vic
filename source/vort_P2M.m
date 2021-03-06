function wf = vort_P2M(SIM, Mesh, nPart, xp, ap, hp, runMode_P2M)

mbc  = SIM.mbc;
dx   = Mesh.dx(1); 
dy   = Mesh.dx(2);
dz   = Mesh.dx(3);
Nx   = Mesh.NX(1);
Ny   = Mesh.NX(2);
Nz   = Mesh.NX(3);
xMin = Mesh.xf{1}(1);
yMin = Mesh.xf{2}(1);
zMin = Mesh.xf{3}(1);

switch runMode_P2M
    case 'CPU-v1'
        % Standard serial code.
      
        wf_x  = zeros(Nx, Ny, Nz);
        wf_y  = zeros(Nx, Ny, Nz);
        wf_z  = zeros(Nx, Ny, Nz);
        for i = 1:Nx
            for j = 1:Ny
                for k = 1:Nz
                    for p = 1:nPart
                        r           = [Mesh.x(i) - xp(1,p); 
                                       Mesh.y(j) - xp(2,p); 
                                       Mesh.z(k) - xp(3,p)];
                        K           = molKernel(r,hp);
                        vort        = ap(1:3,p) .* K;
                        wf_x(i,j,k) = wf_x(i,j,k) + vort(1); % summation NOTE: will this type of summation work on the GPU or in parallel?
                        wf_y(i,j,k) = wf_y(i,j,k) + vort(2);
                        wf_z(i,j,k) = wf_z(i,j,k) + vort(3);
                    end
                end
            end
        end
        
    case 'CPU-v2'   
        % transform the 3 for loops into a single parfor loop.
        
        wf_x  = zeros(Nx, Ny, Nz);
        wf_y  = zeros(Nx, Ny, Nz);
        wf_z  = zeros(Nx, Ny, Nz);
        parfor idx = 1:(Nx*Ny*Nz);
            [i, j, k] = ind2sub([Nx Ny Nz], idx);
            xf        = xMin + (i-1)*dx;
            yf        = yMin + (j-1)*dy;
            zf        = zMin + (k-1)*dz;
            
            % for each mesh point, sum the contribution from ALL particles
            vort_sum = zeros(3, 1);
            for n = 1:nPart
                r        = [xf - xp(1,n); 
                            yf - xp(2,n); 
                            zf - xp(3,n)];
                K        = molKernel(r,hp);
                vort     = ap(:,n) .* K;
                vort_sum = vort_sum + vort;
            end
            wf_x(idx) = vort_sum(1);
            wf_y(idx) = vort_sum(2);
            wf_z(idx) = vort_sum(3);              
        end
        
    case 'GPU-v1'
        
        % transfer the mesh and particle data to the GPU
        dev_hp   = gpuArray( hp );
        dev_xp_x = gpuArray( xp(1, 1:nPart) );
        dev_xp_y = gpuArray( xp(2, 1:nPart) );
        dev_xp_z = gpuArray( xp(3, 1:nPart) );
        dev_ap_x = gpuArray( ap(1, 1:nPart) );
        dev_ap_y = gpuArray( ap(2, 1:nPart) );
        dev_ap_z = gpuArray( ap(3, 1:nPart) ); 
        
        % allocate the field vorticity on the GPU
        dev_wf_x = gpuArray.zeros(Nx+2*mbc, Ny+2*mbc, Nz+2*mbc);
        dev_wf_y = gpuArray.zeros(Nx+2*mbc, Ny+2*mbc, Nz+2*mbc);
        dev_wf_z = gpuArray.zeros(Nx+2*mbc, Ny+2*mbc, Nz+2*mbc);
        
%         parfor idx = 1:(Nx*Ny*Nz);
        parfor idx = 1:(Nx*Ny*Nz + 2*mbc*SIM.dim);
            [i, j, k] = ind2sub([Nx+2*mbc, Ny+2*mbc, Nz+2*mbc], idx);
            xf        = gpuArray( xMin + (i-1)*dx );
            yf        = gpuArray( yMin + (j-1)*dy );
            zf        = gpuArray( zMin + (k-1)*dz );
            
            dev_rx = xf - dev_xp_x;
            dev_ry = yf - dev_xp_y;
            dev_rz = zf - dev_xp_z;
            [dev_wf_x_pc, dev_wf_y_pc, dev_wf_z_pc] = arrayfun(@induce_vort_gpu_v1, dev_rx, ...
                                                                                    dev_ry, ...
                                                                                    dev_rz, ...
                                                                                    dev_hp, ...
                                                                                    dev_ap_x, ...
                                                                                    dev_ap_y, ...
                                                                                    dev_ap_z);
            dev_wf_x(idx) = sum(dev_wf_x_pc);
            dev_wf_y(idx) = sum(dev_wf_y_pc);
            dev_wf_z(idx) = sum(dev_wf_z_pc);
        end
        
        % transfer the arrays on the GPU back onto the CPU
        wf_x = gather( dev_wf_x );
        wf_y = gather( dev_wf_y );
        wf_z = gather( dev_wf_z );
        
  case 'GPU-v2'
        
    otherwise
        error('[Error] Unrecognized input for variable: runMode');
end

wf = {wf_x; wf_y; wf_z};

end % function velField

function f = molKernel(r,hp)

tol   = 1e-6;

r_mag  = norm(r);
r_mag2 = r_mag^2;
hp2    = hp^2;
hp3    = hp^3;
f = 0;
if r_mag > tol
    f = exp(-r_mag2/(2*hp2)) / (2*pi*hp3)^(3/2);
end

end % function


