function update_focus_display(hObject, handles )


% [I_f,windowsize_f,noverlap_f,nfft_f,rate_f,box_f,s_f,fr_f,ti_f,audio_f,AudioRange_f, window_start] = CreateFocusSpectrogram(handles.data.calls(handles.data.currentcall,:),handles);


% [spectogram_y_lims, s_f,fr_f] = cutSpectogramFrequency(s_f, fr_f,handles);

% padding_value_index = get(handles.focusWindowSizePopup,'Value');
% windowsize_value =  get(handles.focusWindowSizePopup,'String');
% window_size = regexp(windowsize_value{padding_value_index},'([\d*.])*','match');
% window_size = str2num(window_size{1}) / 2;

% s_f  = handles.data.page_spect.s(:,handles.data.page_spect.t > handles.current_focus_position(1) & handles.data.page_spect.t < sum(handles.current_focus_position([1,3])));
% ti_f = handles.data.page_spect.t(  handles.data.page_spect.t > handles.current_focus_position(1) & handles.data.page_spect.t < sum(handles.current_focus_position([1,3])));
% fr_f = handles.data.page_spect.f;


% [spectogram_y_lims, s_f,fr_f] = cutSpectogramFrequency(s_f, fr_f,handles);




% Plot Spectrogram
set(handles.axes1,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',[0 get_spectogram_max(hObject,handles)]);
% set(handles.axes1,'YDir', 'normal','YColor',[1 1 1],'XColor',[1 1 1],'Clim',prctile(s_f,[1,99.9],'all'))

% set(handles.spect,'Parent',handles.axes1);
% set(handles.spect,'CData',(scaleSpectogram(s_f)),'XData', ti_f,'YData',fr_f/1000);
set(handles.axes1,'Parent',handles.hFig);
set(handles.axes1,'Xlim', [handles.current_focus_position(1), handles.current_focus_position(1) + handles.current_focus_position(3)]);
set(handles.axes1,'Ylim',[handles.data.settings.LowFreq, min(handles.data.settings.HighFreq, handles.data.audiodata.sample_rate/2000)]);

%Update spectogram ticks and transform labels to
%minutes:seconds.milliseconds
x_min_max = xlim(handles.axes1);
x_ticks = linspace(x_min_max(1), x_min_max(2),handles.data.settings.spectogram_ticks);
xticks(handles.axes1, x_ticks(2:end-1) );
set_tick_timestamps(handles.axes1,true);

% set(handles.axes1,'ylim',[spectogram_y_lims(1)/1000 spectogram_y_lims(2)/1000]);

[I_f,windowsize_f,noverlap_f,nfft_f,rate_f,box_f,s_f,fr_f,ti_f,audio_f,AudioRange_f, window_start] = CreateFocusSpectrogram(handles.data.calls(handles.data.currentcall,:),handles,true);
stats = CalculateStats(I_f,windowsize_f,noverlap_f,nfft_f,rate_f,box_f,handles.data.settings.EntropyThreshold,handles.data.settings.AmplitudeThreshold);

handles.data.calls.Power(handles.data.currentcall) = stats.MaxPower;


% plot Ridge Detection
set(handles.ContourScatter,'XData',stats.ridgeTime','YData',stats.ridgeFreq_smooth);
set(handles.axes7,'Xlim',[1 size(I_f,2)],'Ylim',[1 size(I_f,1)]);

% Plot Slope
X = [ones(size(stats.ridgeTime)); stats.ridgeTime]';
ls = X \ (stats.ridgeFreq_smooth);
handles.ContourLine.XData = [1 size(I_f,2)];
handles.ContourLine.YData = [ls(1), ls(1) + ls(2) * size(I_f,2)];


% Update call statistics text
set(handles.Ccalls,'String',['Call: ' num2str(handles.data.currentcall) '/' num2str(height(handles.data.calls))]);
set(handles.score,'String',['Score: ' num2str(handles.data.calls.Score(handles.data.currentcall))]);
if handles.data.calls.Accept(handles.data.currentcall)
    set(handles.status,'String','Accepted');
    set(handles.status,'ForegroundColor',[0,1,0]); 
else
    set(handles.status,'String','Rejected');
    set(handles.status,'ForegroundColor',[1,0,0])       
end
set(handles.text19,'String',['Label: ' char(handles.data.calls.Type(handles.data.currentcall))]);
set(handles.freq,'String',['Frequency: ' num2str(stats.PrincipalFreq,'%.1f') ' kHz']);
set(handles.slope,'String',['Slope: ' num2str(stats.Slope,'%.3f') ' kHz/s']);
set(handles.duration,'String',['Duration: ' num2str(stats.DeltaTime*1000,'%.0f') ' ms']);
set(handles.sinuosity,'String',['Sinuosity: ' num2str(stats.Sinuosity,'%.4f')]);
set(handles.powertext,'String',['Avg. Power: ' num2str(handles.data.calls.Power(handles.data.currentcall)) ' dB/Hz'])
set(handles.tonalitytext,'String',['Avg. Tonality: ' num2str(stats.SignalToNoise,'%.4f')]);

% Waveform
PlotAudio = audio_f(max(AudioRange_f(1),1):AudioRange_f(2));
% PlotAudio = highpass(PlotAudio, box_f(4)*500, handles.data.audiodata.sample_rate);
% set(handles.Waveform,...
%     'XData', length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),...
%     'YData', 0.5 .* PlotAudio ./ max(PlotAudio) - 0.5)

set(handles.Waveform,...
'XData', length(stats.Entropy) * ((1:length(PlotAudio)) / length(PlotAudio)),...
'YData', (PlotAudio/max(PlotAudio)-.5))


% SNR
y = 0-stats.Entropy;
x = 1:length(stats.Entropy);
z = zeros(size(x));
col = double(stats.Entropy < 1-handles.data.settings.EntropyThreshold);  % This is the color, vary with x in this case.
set(handles.SNR, 'XData', [x;x], 'YData', [y;y], 'ZData', [z;z], 'CData', [col;col]);
colormap(handles.axes3,parula);
set(handles.axes3, 'XLim', [x(1), x(end)]);

guidata(hObject, handles);
end
