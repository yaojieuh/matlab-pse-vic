function w_du = vortex_stretch(SIM, MESH, wf, uf)
% compute the velocity gradient
[dx_ufx, dy_ufx, dz_ufx] = gradient(uf{1}, MESH.dx(1), MESH.dx(2), MESH.dx(3));
[dx_ufy, dy_ufy, dz_ufy] = gradient(uf{2}, MESH.dx(1), MESH.dx(2), MESH.dx(3));
[dx_ufz, dy_ufz, dz_ufz] = gradient(uf{3}, MESH.dx(1), MESH.dx(2), MESH.dx(3));

% compute the vorticity gradient
% [dx_wfx, dy_wfx, dz_wfx] = gradient(wf{1}, MESH.dx(1), MESH.dx(2), MESH.dx(3));
% [dx_wfy, dy_wfy, dz_wfy] = gradient(wf{2}, MESH.dx(1), MESH.dx(2), MESH.dx(3));
% [dx_wfz, dy_wfz, dz_wfz] = gradient(wf{3}, MESH.dx(1), MESH.dx(2), MESH.dx(3));

% compute the vortex stretching term
w_du_x = wf{1}.*dx_ufx + wf{2}.*dy_ufx + wf{3}.*dz_ufx;
w_du_y = wf{1}.*dx_ufy + wf{2}.*dy_ufy + wf{3}.*dz_ufy;
w_du_z = wf{1}.*dx_ufz + wf{2}.*dy_ufz + wf{3}.*dz_ufz;
w_du   = {w_du_x; w_du_y; w_du_z};

end % function

function sf = strain_rate(SIM, MESH, wf, uf)


%% determine max indicies depending on periodicity (N+1)
if SIM.domainbc == 0 % freespace boundary conditions
    imax = MESH.NX(1) - mbc;
    jmax = MESH.NX(2);
    kmax = MESH.NX(3);
else % periodic boundary conditions
    imax = snx(1)-1;
    jmax = snx(2)-1;
    kmax = snx(3)-1;
end

%%------------------------------------------------------------------
% Compute maximum strainrate O(4) FD - converted from Naga code
%-------------------------------------------------------------------

% without using ghost layers, we have left and right edge formulas at the
% boundaries.  If using ghost layers, only central difference formulas are
% needed.

dx = MESH.dx(1);
dy = MESH.dx(2);
dz = MESH.dx(3);

facx = 1.0/(dx*12.0);
facy = 1.0/(dy*12.0);
facz = 1.0/(dz*12.0);

mbc = 2;    % ghost layer, size of finite diff stencil

for k = 1+mbc:MESH.NX(3)+mbc
    for j = 1+mbc:MESH.NX(2)+mbc
        for i = 1+mbc:MESH.NX(1)+mbc
            dudx =  -    facx*uf{1}(i+2,j  ,k  ) ...
                    +8.0*facx*uf{1}(i+1,j  ,k  ) ...
                    -8.0*facx*uf{1}(i-1,j  ,k  ) ...
                    +    facx*uf{1}(i-2,j  ,k  );
         
            dvdx =  -    facx*uf{2}(i+2,j  ,k  ) ...
                    +8.0*facx*uf{2}(i+1,j  ,k  ) ...
                    -8.0*facx*uf{2}(i-1,j  ,k  ) ...
                    +    facx*uf{2}(i-2,j  ,k  );
      
            dwdx =  -    facx*uf{3}(i+2,j  ,k  ) ...
                    +8.0*facx*uf{3}(i+1,j  ,k  ) ...
                    -8.0*facx*uf{3}(i-1,j  ,k  ) ...
                    +    facx*uf{3}(i-2,j  ,k  );
                
            dudy =  -    facy*uf{1}(i  ,j+2,k  ) ...
                    +8.0*facy*uf{1}(i  ,j+1,k  ) ...
                    -8.0*facy*uf{1}(i  ,j-1,k  ) ...
                    +    facy*uf{1}(i  ,j-2,k  );
                
            dvdy =  -    facy*uf{2}(i  ,j+2,k  ) ...
                    +8.0*facy*uf{2}(i  ,j+1,k  ) ...
                    -8.0*facy*uf{2}(i  ,j-1,k  ) ...
                    +    facy*uf{2}(i  ,j-2,k  );
                
            dwdy =  -    facy*uf{3}(i  ,j+2,k  ) ...
                    +8.0*facy*uf{3}(i  ,j+1,k  ) ...
                    -8.0*facy*uf{3}(i  ,j-1,k  ) ...
                    +    facy*uf{3}(i  ,j-2,k  );
                
            dudz =  -    facz*uf{1}(i  ,j  ,k+2) ...
                    +8.0*facz*uf{1}(i  ,j  ,k+1) ...
                    -8.0*facz*uf{1}(i  ,j  ,k-1) ...
                    +    facz*uf{1}(i  ,j  ,k-2);
                
            dvdz =  -    facz*uf{2}(i  ,j  ,k+2) ...
                    +8.0*facz*uf{2}(i  ,j  ,k+1) ...
                    -8.0*facz*uf{2}(i  ,j  ,k-1) ...
                    +    facz*uf{2}(i  ,j  ,k-2);
                
            dwdz =  -    facz*uf{3}(i  ,j  ,k+2) ...
                    +8.0*facz*uf{3}(i  ,j  ,k+1) ...
                    -8.0*facz*uf{3}(i  ,j  ,k-1) ...
                    +    facz*uf{3}(i  ,j  ,k-2);
        end
    end
end


% field gradient
% sf{m,n} = 
sf = {dudx, dvdx, dwdx; ...
      dudy, dvdy, dwdy; ...
      dudz, dvdz, dwdz};
  
end % function


