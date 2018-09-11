function [state,pars,add] = plot_atmos(fname, opts)

    if nargin < 2
        opts = [];
    end
    
    if nargin < 1
        fname = 'atmos_output.h5';
    end
    
    if nargin < 2 % defaults
        readEP  = true;
        readLST = true;      
        
        opts.readEP  = readEP;
        opts.readLST = readLST;
    end
    
    if isfield(opts, 'readEP')
        readEP = opts.readEP;
    else
        readEP = false;
        opts.readEP = readEP;
    end

    if isfield(opts, 'readLST')
        readLST = opts.readLST;
    else
        readLST = false;
    end

    if isfield(opts, 'readFluxes')
        readFluxes = opts.readFluxes;
    else
        readFluxes = false;
    end

    if isfield(opts, 'Ta')
        plot_ta = opts.Ta;
    else
        plot_ta = false;
    end

    if isfield(opts, 'humidity')
        plot_humidity = opts.humidity;
    else
        plot_humidity = false;
    end

    if isfield(opts, 'albedo')
        plot_albedo = opts.albedo;
    else
        plot_albedo = false;
    end

    if isfield(opts, 'invert')
        invert = opts.invert;
    else
        invert = false;
        opts.invert = invert;
    end
    
    if isfield(opts, 'fig_ctr')
        fig_ctr = opts.fig_ctr;
    else
        fig_ctr = 11; % first figure handle number
    end

    if isfield(opts, 'fname_add')
        export_to_file = true;
    else
        export_to_file = false;
    end

    [n m l la nun xmin xmax ymin ymax hdim x y z xu yv zw landm] = readfort44('fort.44');
    surfm      = landm(2:n+1,2:m+1,l+1);    % Only interior surface points
    landm_int  = landm(2:n+1,2:m+1,2:l+1);
    summask = sum(landm_int,3);

    srf = [];
    greyness = .85;
    srf(:,:,1) = (1-greyness*(surfm'));
    srf(:,:,2) = (1-greyness*(surfm'));
    srf(:,:,3) = (1-greyness*(surfm'));

    atmos_nun = 3;
    atmos_l   = 1;
    
    [state, pars, add] = readhdf5(fname, atmos_nun, n, m, atmos_l,opts);
    
    if readEP
        E = reshape(add.E,n,m);
        P = reshape(add.P,n,m);
    end

    if readLST
        LST = reshape(add.LST, n, m);
        SST = reshape(add.SST, n, m);
    end

    RtD = 180/pi;    
    
    % reference temperature
    T0  = 15.0;   
    q0  = 8e-3;
    a0  = 0.3;
    
    % starlings
    tdim = 1;
    qdim = 1e-3;
    adim = 0.5;

    % constants
    rhoa = 1.25;
    rhoo = 1024;
    ce   = 1.3e-03;
    uw   = 8.5;
    eta  =  (rhoa / rhoo) * ce * uw;
    
    Ta  = T0 + tdim * squeeze(state(1,:,:,:));
    qa  = q0 + qdim * squeeze(state(2,:,:,:));
    qa(logical(surfm)) = NaN; % humidity above land points does not contribute 
    Aa  = a0 + adim * squeeze(state(3,:,:,:));
    Tz  = mean(Ta,1); % zonal mean
    qz  = mean(qa,1); % zonal mean

    if plot_ta
        figure(fig_ctr); fig_ctr = fig_ctr+1;

        img = Ta';
        Tdiff = max(max(Ta))-min(min(Ta));
        fprintf('max(T) - min(T) = %f\n', Tdiff);
        %contourf(RtD*x,RtD*(y),img,20,'Visible','off'); hold on;
        image(RtD*x,RtD*(y),srf,'AlphaData',1); hold on
        contour(RtD*x,RtD*(y),img,15,'linewidth',2); hold on;
        set(gca,'ydir','normal')
        %c = contour(RtD*x,RtD*(y),img,20,'Visible', 'on','linewidth',1.5);
        colorbar
        cmap = my_colmap(caxis);
        colormap(cmap)
        colorbar

        hold off
        
        title('Atmospheric temperature')
        xlabel('Longitude')
        ylabel('Latitude')
        
        if export_to_file
            exportfig('atmosTemp.eps',10,[14,10],invert)
        end
    end

    if plot_humidity
        figure(fig_ctr); fig_ctr = fig_ctr+1;
        img = qa';

        image(RtD*x,RtD*(y),srf,'AlphaData',.2); hold on
        set(gca,'ydir','normal')
        hold on
        c = contour(RtD*x,RtD*(y),img,12,'Visible', 'on', ...
                    'linewidth',1.5);
        hold off
        
        colorbar
        cmap = my_colmap(caxis);
        colormap(cmap)

        drawnow
        title('Humidity (kg / kg)')
        xlabel('Longitude')
        ylabel('Latitude')
        
        if export_to_file
            exportfig('atmosq.eps',10,[14,10],invert)
        end
    end
    
    if plot_albedo
        figure(fig_ctr); fig_ctr = fig_ctr+1;
        img = Aa';
        imagesc(RtD*x,RtD*(y),img); 
        set(gca,'ydir','normal')
        
        %cmap = my_colmap(caxis);
        colormap(gray)
        colorbar

        title('Albedo')
        xlabel('Longitude')
        ylabel('Latitude')
        
        if export_to_file
            exportfig('atmosA.eps',10,[14,10],invert)
        end
    end
    
    if readEP

        Pd  = eta*qdim*max(max(P))*3600*24*365;
        fprintf('Precipitation P = %2.4e m/y\n', Pd);
        
        figure(fig_ctr); fig_ctr = fig_ctr+1;        
        EmP = eta*qdim*(E-P)*3600*24*365;
        img = EmP';

        imagesc(RtD*x,RtD*(y),img); hold on
        img(img == 0) = NaN;
        c = contour(RtD*x,RtD*(y),img,20,'k','Visible', 'on', ...
                    'linewidth',.5);
        hold off
        set(gca,'ydir','normal')
        cmap = my_colmap(caxis,0);
        colormap(cmap)
        colorbar

        hold off        
        
        title('E-P (m/y)')
        xlabel('Longitude')
        ylabel('Latitude')
        
        if export_to_file
            exportfig('atmosEmP.eps',10,[14,10],invert)
        end
    end
    
    if readLST
        figure(fig_ctr); fig_ctr = fig_ctr+1;
        imagesc(RtD*x,RtD*(y), SST' + LST' + T0);
        set(gca,'ydir', 'normal');
        cmap = my_colmap(caxis, 0);
        colormap(cmap)                
        colorbar
        title('Surface temperature')
        xlabel('Longitude')
        ylabel('Latitude')
    end

    if readFluxes
        plot_fluxes(add, fig_ctr,'Atmos: ', opts); 
    end
end