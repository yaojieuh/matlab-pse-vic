function dx_dt = ode_RHS(t, x, CTRL, SIM, MESH, PART, ENV)

%% bookkeeping for ODE solver
% reshape the array into more meaningful variable names
nVars = 2;
tmp   = reshape(       x, SIM.dim*PART.nPart, nVars);  
xp    = reshape(tmp(:,1),         PART.nPart, SIM.dim)';    % particle positions
% wp    = reshape(tmp(:,2),         PART.nPart, SIM.dim)';    % particle weights (vorticity)
ap    = reshape(tmp(:,2),         PART.nPart, SIM.dim)';    % particle strengths (circulation)
wp    = ap ./ PART.vol;

%% Vortex-in-Cell algorithm
wf         = interp_P2M(SIM, MESH, xp, wp);       	% init a new vorticity field by interpolation from particles (P2M)
uf         = PoissonSolve3D(SIM, MESH, wf);      	% solve Poisson eqn for velocity
% (more to come here)                           	% compute strain rate for use in diagnostics and/or LES model
% (more to come here)                               % perform some diagnostics on velocity and vorticity fields
up         = interp_M2P(SIM, MESH, xp, uf);       	% interpolate velocity field to particles (M2P) - the Poisson solver should already have extrapolated velocity into the ghost layer
[uf, up]   = add_freestream(uf, up, ENV);           % add the freestream velocity (Helmholtz decomposition)
dwf        = vorticity_rhs(SIM, MESH, wf, uf);   	% compute RHS of vorticity transport eqn - this includes vortex stretching and diffusion calculated on mesh (finite differences) - the mesh and fields should be ghosted/extrpolated before calling
dwp        = interp_M2P(SIM, MESH, xp, dwf);      	% interpolate vorticity RHS from mesh to particles

%% collect the output
dx_dt = [reshape( up', SIM.dim*PART.nPart, 1); 
         reshape(dwp', SIM.dim*PART.nPart, 1)];     

%% write diagnostics     
fprintf(1, '[ode_RHS.m] time = %g\n', t);

    %% make some quick plots for debugging
    plot_field(wf, MESH, 'vorticity field')
    % plot_field(uf, MESH, 'velocity field')
    % plot_particles(xp, wp, MESH, 'particle vorticity')
    plot_particles(xp, up, MESH, 'particle velocity')
    
end % function