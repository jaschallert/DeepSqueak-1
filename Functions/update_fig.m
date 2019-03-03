function update_fig(hObject, eventdata, handles)
% profile on
% Update the display
if ~isfield(handles,'calls') 
    return
end
    
if isempty(handles.calls)
    errordlg('No calls in file')
    return
end

% Get spectrogram data
[I,windowsize,noverlap,nfft,rate,box,s,fr,ti,audio,AudioRange] = CreateSpectrogram(handles.calls(handles.currentcall, :));

% Plot Spectrogram
set(handles.axes1,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 2*mean(max(I))]);
% colormap(handles.axes1,handles.cmap);
set(handles.spect,'CData',imgaussfilt(abs(s)),'XData',ti,'YData',fr/1000);

if handles.settings.DisplayTimePadding ~=0;
    meantime = handles.calls.RelBox(handles.currentcall, 1) + handles.calls.RelBox(handles.currentcall, 3) / 2;
    set(handles.axes1,'Xlim',[meantime - (handles.settings.DisplayTimePadding / 2), meantime + (handles.settings.DisplayTimePadding / 2)], 'color', 'k')
else
    set(handles.axes1,'Xlim',[handles.spect.XData(1) handles.spect.XData(end)])
end

set(handles.axes1,'ylim',[handles.settings.LowFreq handles.settings.HighFreq]);
stats = CalculateStats(I,windowsize,noverlap,nfft,rate,box,handles.settings.EntropyThreshold,handles.settings.AmplitudeThreshold);

handles.calls.Power(handles.currentcall) = stats.MaxPower;

% Update slider with the call ID 
set(handles.slider1, 'Value', (handles.currentcall-1) / (height(handles.calls)-1));

% Box Creation
if handles.calls.Accept(handles.currentcall)
    set(handles.box,'Position',handles.calls.RelBox(handles.currentcall, :),'EdgeColor','g')
else
    set(handles.box,'Position',handles.calls.RelBox(handles.currentcall, :),'EdgeColor','r')
end

% Blur Box
set(handles.filtered_image_plot,'CData',flipud(stats.FilteredImage))
set(handles.axes4,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Clim',[.2*min(min(stats.FilteredImage)) .2*max(max(stats.FilteredImage))],'XLim',[1 size(stats.FilteredImage,2)],'YLim',[1 size(stats.FilteredImage,1)]);
colormap(handles.axes4,handles.cmap);
set(handles.axes4,'YTickLabel',[]);
set(handles.axes4,'XTickLabel',[]);
set(handles.axes4,'XTick',[]);
set(handles.axes4,'YTick',[]);

% plot Ridge Detection
set(handles.ContourScatter,'XData',stats.ridgeTime','YData',stats.ridgeFreq_smooth);
set(handles.axes7,'Xlim',[1 length(stats.FilteredImage(1,:))],'Ylim',[1 length(stats.FilteredImage(:,1))]);


% Delete everything except the scatter
delete(handles.axes7.Children(1:end-1));
ContourLine = lsline(handles.axes7);
set(ContourLine,'LineStyle','--','Color','y');

% Update call statistics text
set(handles.Ccalls,'String',['Call: ' num2str(handles.currentcall) '/' num2str(height(handles.calls))])
set(handles.score,'String',['Score: ' num2str(handles.calls.Score(handles.currentcall))])
if handles.calls.Accept(handles.currentcall)
    set(handles.status,'String','Accepted')
else
    set(handles.status,'String','Rejected')
end
set(handles.text19,'String',['Label: ' char(handles.calls.Type(handles.currentcall))]);
set(handles.freq,'String',['Frequency: ' num2str(stats.PrincipalFreq,'%.1f') ' kHz']);
set(handles.slope,'String',['Slope: ' num2str(stats.Slope,'%.3f') ' kHz/s']);
set(handles.duration,'String',['Duration: ' num2str(stats.DeltaTime*1000,'%.0f') ' ms']);
set(handles.sinuosity,'String',['Sinuosity: ' num2str(stats.Sinuosity,'%.4f')]);
set(handles.powertext,'String',['Avg. Power: ' num2str(handles.calls.Power(handles.currentcall)) ' dB/Hz'])
set(handles.tonalitytext,'String',['Avg. Tonality: ' num2str(stats.SignalToNoise,'%.4f')]);

% Waveform
cla(handles.axes3)
hold(handles.axes3,'on')
PlotAudio = audio(AudioRange(1):AudioRange(2));
plot(handles.axes3,length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),(.5*PlotAudio/max(PlotAudio)-.5),'Color',[.1 .75 .75]);


% SNR
y = 0-stats.Entropy;
x = 1:length(stats.Entropy);
z = zeros(size(x));
col = double(stats.Entropy < 1-handles.settings.EntropyThreshold);  % This is the color, vary with x in this case.
surface(handles.axes3,[x;x],[y;y],[z;z],[col;col],...
    'facecol','r',...
    'edgecol','interp',...
    'linew',2);
set(handles.axes3,'YTickLabel',[]);
set(handles.axes3,'XTickLabel',[]);
set(handles.axes3,'XTick',[]);
set(handles.axes3,'YTick',[]);
set(handles.axes3,'Color',[.1 .1 .1],'YColor',[1 1 1],'XColor',[1 1 1],'Box','off','Xlim',[0 length(stats.Entropy)],'Ylim',[-1 0],'Clim',[0 1]);
hold(handles.axes3,'off')

% Plot Call Position
calltime = handles.calls.Box(handles.currentcall, 1);
handles.CurrentCallLinePosition.XData = [calltime, calltime];
if handles.calls.Accept(handles.currentcall)
    handles.CurrentCallLinePosition.Color = [0,1,0];
else
    handles.CurrentCallLinePosition.Color = [1,0,0];
end
set(handles.CurrentCallLineLext,'Position',[calltime,1.2,0],'String',[num2str(stats.BeginTime,'%.1f') ' s']);

guidata(hObject, handles);

