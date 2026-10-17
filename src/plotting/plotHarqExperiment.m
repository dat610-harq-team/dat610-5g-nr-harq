function plotHarqExperiment(summary, figureDir, showFigures, mode)
%PLOTHARQEXPERIMENT Export reliability, goodput, mean retries and retry share.
    visibility = 'off';
    if showFigures, visibility = 'on'; end
    fig = figure('Name','NR HARQ over AWGN','Visible',visibility, ...
        'Color','white','Position',[100 100 1100 760]);
    layout = tiledlayout(fig,2,2,'TileSpacing','compact');
    labels = unique(summary.configuration,'stable');
    colors = lines(numel(labels));
    styles = {'-o','--s',':^','-.d'};
    fields = {'finalResidualBLER','goodputMbps', ...
        'meanRetransmissionsPerDeliveredTb','retransmissionResourceShare'};
    ylabels = {'Final TB failure rate (95% Wilson CI)','TB goodput (Mbit/s)', ...
        'Mean retransmissions | delivered (95% CI)', ...
        'Retransmission share of all attempts'};
    for panel = 1:4
        ax = nexttile(layout);
        set(ax,'Color','white','XColor','black','YColor','black');
        hold(ax,'on'); grid(ax,'on');
        for k = 1:numel(labels)
            style = styles{mod(k-1,numel(styles))+1};
            r = sortrows(summary(summary.configuration==labels(k),:),'snrDb');
            if panel==1
                errorbar(ax,r.snrDb,r.finalResidualBLER, ...
                    r.finalResidualBLER-r.finalBLERLow95, ...
                    r.finalBLERHigh95-r.finalResidualBLER,style, ...
                    'Color',colors(k,:),'DisplayName',labels(k));
            elseif panel==3
                errorbar(ax,r.snrDb,r.meanRetransmissionsPerDeliveredTb, ...
                    r.meanRetransmissionsPerDeliveredTb-r.meanRetxLow95, ...
                    r.meanRetxHigh95-r.meanRetransmissionsPerDeliveredTb,style, ...
                    'Color',colors(k,:),'DisplayName',labels(k));
            else
                plot(ax,r.snrDb,r.(fields{panel}),style, ...
                    'Color',colors(k,:),'DisplayName',labels(k));
            end
        end
        xlabel(ax,'PDSCH symbol E_s/N_0 (dB)'); ylabel(ax,ylabels{panel});
        if panel==4, ylim(ax,[0 1]); end
        if panel==1
            ylim(ax,[0 1]);
            legend(ax,'Location','best','Interpreter','none', ...
                'Color','white','TextColor','black');
        end
    end
    title(layout,sprintf('NR DL-SCH/PDSCH, AWGN, ideal feedback (%s)',mode),'Color','black');
    if strlength(figureDir)>0
        exportgraphics(fig,fullfile(figureDir,'harq_comparison.png'),'Resolution',180);
        savefig(fig,fullfile(figureDir,'harq_comparison.fig'));
    end
    if ~showFigures, close(fig); end
end
