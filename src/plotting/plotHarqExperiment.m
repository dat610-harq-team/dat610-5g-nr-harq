function plotHarqExperiment(summary, figureDir, showFigures, mode)
%PLOTHARQEXPERIMENT Export reliability, goodput, retransmission and delay plots.
    visibility = 'off';
    if showFigures, visibility = 'on'; end
    fig = figure('Name','NR HARQ over AWGN','Visible',visibility,'Position',[100 100 1100 760]);
    layout = tiledlayout(fig,2,2,'TileSpacing','compact');
    labels = unique(summary.configuration,'stable');
    colors = lines(numel(labels));
    styles = {'-o','--s',':^','-.d'};
    fields = {'finalResidualBLER','goodputMbps', ...
        'meanRetransmissionsPerDeliveredTb','meanAttemptsPerDeliveredTb'};
    ylabels = {'Final TB failure rate (95% Wilson CI)','TB goodput (Mbit/s)', ...
        'Mean retransmissions | delivered','Mean attempts | delivered'};
    for panel = 1:4
        ax = nexttile(layout); hold(ax,'on'); grid(ax,'on');
        for k = 1:numel(labels)
            style = styles{mod(k-1,numel(styles))+1};
            r = sortrows(summary(summary.configuration==labels(k),:),'snrDb');
            if panel==1
                errorbar(ax,r.snrDb,r.finalResidualBLER, ...
                    r.finalResidualBLER-r.finalBLERLow95, ...
                    r.finalBLERHigh95-r.finalResidualBLER,style, ...
                    'Color',colors(k,:),'DisplayName',labels(k));
            else
                plot(ax,r.snrDb,r.(fields{panel}),style, ...
                    'Color',colors(k,:),'DisplayName',labels(k));
            end
        end
        xlabel(ax,'PDSCH symbol E_s/N_0 (dB)'); ylabel(ax,ylabels{panel});
        if panel==1, ylim(ax,[0 1]); legend(ax,'Location','best','Interpreter','none'); end
    end
    title(layout,sprintf('NR DL-SCH/PDSCH, AWGN, ideal feedback (%s)',mode));
    if strlength(figureDir)>0
        exportgraphics(fig,fullfile(figureDir,'harq_comparison.png'),'Resolution',180);
        savefig(fig,fullfile(figureDir,'harq_comparison.fig'));
    end
    if ~showFigures, close(fig); end
end
