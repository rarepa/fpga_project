/*
  ==============================================================================

	This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
PluginAudioProcessor::PluginAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
	: AudioProcessor(BusesProperties()
#if ! JucePlugin_IsMidiEffect
#if ! JucePlugin_IsSynth
		.withInput("Input", juce::AudioChannelSet::stereo(), true)
#endif
		.withOutput("Output", juce::AudioChannelSet::stereo(), true)
#endif
	),
	parameters(*this, nullptr, "parameters", createParameterLayout())
#endif
{
	initParametersValue();

	ids = { "0x19", "0x1A", "0x1B", "0x34", "0x18", "0x1E", "0x1F", "0x20", "0x35", "0x1D", "0x21",
		"0x12", "0x14", "0x37", "0x05", "0x0D", "0x0E", "0x0F", "0x15", "0x16", "0x06", "0x07", "0x08",
		"0x09", "0x0A", "0x0B", "0x0C", "0x39", "0x10" };

	for (int i = 0; i < ids.size(); i++) {
		// adds a listener for each ID
		parameters.addParameterListener(ids[i], this);
	}

	state = INITIAL;

	write_json_file = false;
	readJsonFile();

	if (!readIniFile())
		com_port_value = "COM4";

#if !STANDALONE
	// FPGA-UART connection only at plug-in load
	FPGA_Connection();
	send_pvalues();
#endif
}

PluginAudioProcessor::~PluginAudioProcessor()
{
	CloseHandle(hComm);

	if (write_json_file)
		write_json();
}

//==============================================================================
const juce::String PluginAudioProcessor::getName() const
{
	return JucePlugin_Name;
}

bool PluginAudioProcessor::acceptsMidi() const
{
#if JucePlugin_WantsMidiInput
	return true;
#else
	return false;
#endif
}

bool PluginAudioProcessor::producesMidi() const
{
#if JucePlugin_ProducesMidiOutput
	return true;
#else
	return false;
#endif
}

bool PluginAudioProcessor::isMidiEffect() const
{
#if JucePlugin_IsMidiEffect
	return true;
#else
	return false;
#endif
}

double PluginAudioProcessor::getTailLengthSeconds() const
{
	return 0.0;
}

int PluginAudioProcessor::getNumPrograms()
{
	return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
				// so this should be at least 1, even if you're not really implementing programs.
}

int PluginAudioProcessor::getCurrentProgram()
{
	return 0;
}

void PluginAudioProcessor::setCurrentProgram(int index)
{
}

const juce::String PluginAudioProcessor::getProgramName(int index)
{
	return {};
}

void PluginAudioProcessor::changeProgramName(int index, const juce::String& newName)
{
}

//==============================================================================
void PluginAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
	// Use this method as the place to do any pre-playback
	// initialisation that you need..
}

void PluginAudioProcessor::releaseResources()
{
	// When playback stops, you can use this as an opportunity to free up any
	// spare memory, etc.
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool PluginAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
#if JucePlugin_IsMidiEffect
	juce::ignoreUnused(layouts);
	return true;
#else
	// This is the place where you check if the layout is supported.
	// In this template code we only support mono or stereo.
	// Some plugin hosts, such as certain GarageBand versions, will only
	// load plugins that support stereo bus layouts.
	if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
		&& layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
		return false;

	// This checks if the input layout matches the output layout
#if ! JucePlugin_IsSynth
	if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
		return false;
#endif

	return true;
#endif
}
#endif

void PluginAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
	juce::ScopedNoDenormals noDenormals;
	auto totalNumInputChannels = getTotalNumInputChannels();
	auto totalNumOutputChannels = getTotalNumOutputChannels();

	for (const juce::MidiMessageMetadata metadata : midiMessages) {
		//juce::String str = juce::String(metadata.getMessage().getChannel()) + " " + juce::String(metadata.getMessage().getControllerNumber()) + " " + juce::String(metadata.getMessage().getControllerValue()) + "\n";
		//juce::File("C:\\test\\filename.txt").appendText(str);
		if (metadata.getMessage().isController()) {
#if STANDALONE
			int channel = (int)metadata.getMessage().getChannel();
			int control = (int)metadata.getMessage().getControllerNumber();
			int value = (int)metadata.getMessage().getControllerValue();

			if (learning) {
				update_midicc(channel, control);
				learning = false;
			}
			else {
				if (midi_cc.contains(channel)) {
					juce::String id = midi_cc[channel][control];
					if (midi_comp.contains(id)) {
						juce::Component* c = midi_comp[id].first;
						int type = midi_comp[id].second;
						// actualizar el valor del componente
						if (type == 2) {
							juce::Slider* sl = (juce::Slider*)c;
							const juce::MessageManagerLock mmLock;
							if (c->getComponentID() == "0x19" || c->getComponentID() == "0x1E") { // de -12 a 12
								int valor = juce::roundToInt((value - 64) * (12.0 / 64.0));
								sl->setValue(valor, juce::dontSendNotification);
							}
							else if (c->getComponentID() == "0x12" || c->getComponentID() == "0x14" || c->getComponentID() == "0x0D") { // de 0 a 127
								sl->setValue(value, juce::dontSendNotification);
							}
							else { // de 0 a 100
								int valor = juce::roundToInt(value * (100.0 / 127.0));
								sl->setValue(valor, juce::dontSendNotification);
							}
						}
					}
				}
			}
#endif
		}
		else {
			DWORD byteswritten = 0;
			int send_data = 0x00;
			if (metadata.getMessage().isNoteOn()) {
				//juce::File("C:\\test\\filename.txt").appendText("is note on\n");
				send_data = metadata.getMessage().getNoteNumber();
			}

			if (metadata.getMessage().isNoteOff()) {
				//juce::File("C:\\test\\filename.txt").appendText("is note off 0x04\n");
				unsigned char note_release = 0x04;
				WriteFile(hComm, &note_release, 1, &byteswritten, NULL);
				send_data = metadata.getMessage().getNoteNumber();
			}

			if (send_data > 0x00) {
				send_data += 0x7F;
				//juce::File("C:\\test\\filename.txt").appendText("Envia: " + juce::String(send_data) + "\n");
				WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
			}
		}
	}


	// In case we have more outputs than inputs, this code clears any output
	// channels that didn't contain input data, (because these aren't
	// guaranteed to be empty - they may contain garbage).
	// This is here to avoid people getting screaming feedback
	// when they first compile a plugin, but obviously you don't need to keep
	// this code if your algorithm always overwrites all the output channels.
	for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
		buffer.clear(i, 0, buffer.getNumSamples());

	// This is the place where you'd normally do the guts of your plugin's
	// audio processing...
	// Make sure to reset the state if your inner loop is processing
	// the samples and the outer loop is handling the channels.
	// Alternatively, you can process the samples with the channels
	// interleaved by keeping the same state.
	for (int channel = 0; channel < totalNumInputChannels; ++channel)
	{
		auto* channelData = buffer.getWritePointer(channel);

		// ..do something to the data...
	}
}

//==============================================================================
bool PluginAudioProcessor::hasEditor() const
{
	return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* PluginAudioProcessor::createEditor()
{
	return new PluginAudioProcessorEditor(*this, parameters);
}

void PluginAudioProcessor::FPGA_Connection()
{
	BOOL Status;
	DCB dcbSerialParams = { 0 };
	COMMTIMEOUTS timeouts = { 0 };
	DWORD BytesWritten = 0;
	DWORD dwEventMask;
	char ReadData;
	DWORD NoBytesRead;
	//char ComPortName[] = "\\\\.\\COM4";
	std::string st = "\\\\.\\" + com_port_value.toStdString();
	const char* ComPortName = st.c_str();
	connected = false;

	hComm = CreateFile(ComPortName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
	if (hComm == INVALID_HANDLE_VALUE) {
		//printf("\n Port can't be opened\n\n");
		//juce::File("C:\\test\\filename.txt").appendText("Port can't be opened\n");
		return;
	}

	//Setting the Parameters for the SerialPort
	dcbSerialParams.DCBlength = sizeof(dcbSerialParams);
	Status = GetCommState(hComm, &dcbSerialParams);
	if (Status == FALSE) {
		//printf("\nError to Get the Com state\n\n");
		//juce::File("C:\\test\\filename.txt").appendText("Error to Get the Com state\n");
		CloseHandle(hComm);
		return;
	}

	dcbSerialParams.BaudRate = CBR_115200;
	dcbSerialParams.ByteSize = 8;
	dcbSerialParams.StopBits = ONESTOPBIT;
	dcbSerialParams.Parity = NOPARITY;
	Status = SetCommState(hComm, &dcbSerialParams);
	if (Status == FALSE) {
		//printf("\nError to Setting DCB Structure\n\n");
		//juce::File("C:\\test\\filename.txt").appendText("Error to Setting DCB Structure\n");
		CloseHandle(hComm);
		return;
	}

	//Setting Timeouts
	timeouts.ReadIntervalTimeout = 50;
	timeouts.ReadTotalTimeoutConstant = 50;
	timeouts.ReadTotalTimeoutMultiplier = 10;
	timeouts.WriteTotalTimeoutConstant = 50;
	timeouts.WriteTotalTimeoutMultiplier = 10;
	if (SetCommTimeouts(hComm, &timeouts) == FALSE) {
		//printf("\nError to Setting Time outs");
		//juce::File("C:\\test\\filename.txt").appendText("Error to Setting Time outs\n");
		CloseHandle(hComm);
		return;
	}

	connected = true;
	//juce::File("C:\\test\\filename.txt").appendText("FPGA connected\n");

#if STANDALONE
	unsigned char synchronize = 0x01;
	Status = WriteFile(hComm, &synchronize, 1, &BytesWritten, NULL);
	if (Status == FALSE) {
		//printf("\nFail to Written");
		CloseHandle(hComm);
		return;
	}

	//printf("\nNumber of bytes written to the serial port = %d\n\n", BytesWritten);

	Status = SetCommMask(hComm, EV_RXCHAR);
	if (Status == FALSE) {
		//printf("\nError to in Setting CommMask\n\n");
		CloseHandle(hComm);
		return;
	}

	Status = WaitCommEvent(hComm, &dwEventMask, NULL);
	if (Status == FALSE) {
		//printf("\nError! in Setting WaitCommEvent()\n\n");
		CloseHandle(hComm);
		return;
	}

	std::vector<int> data;
	do {
		Status = ReadFile(hComm, &ReadData, sizeof(ReadData), &NoBytesRead, NULL);
		data.push_back(ReadData);
	} while (NoBytesRead > 0);

	int size = data.size() - 1;
	for (int index = 0; index < size; index++) {
		setParamValue(data[index], juce::dontSendNotification);
	}
#endif
}

//==============================================================================

// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
	return new PluginAudioProcessor();
}

//==============================================================================

void PluginAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
#if STANDALONE
	// create xml with state information
	std::unique_ptr <juce::XmlElement> outputXml(parameters.state.createXml());
	// save xml to binary
	copyXmlToBinary(*outputXml, destData);
#else
	juce::MemoryOutputStream stream(destData, true);

	for (int i = 0; i < ids.size(); i++) {
		stream.writeInt(parameters.getParameterAsValue(ids[i]).getValue());
	}

	std::vector<const char*> ids_radios = { "0x17", "0x1C", "0x11", "0x13", "0x36", "0x22", "0x23", "0x38" };
	for (int i = 0; i < ids_radios.size(); i++) {
		stream.writeInt(pvalues[ids_radios[i]]);
	}
#endif
}

void PluginAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
#if STANDALONE
	// create xml from binary
	std::unique_ptr<juce::XmlElement> inputXml(getXmlFromBinary(data, sizeInBytes));
	// check that inputXml returned correctly
	if (inputXml != nullptr)
	{
		// if inputXml tag name matches tree state tag name
		if (inputXml->hasTagName(parameters.state.getType()))
		{
			// copy xml into tree state
			parameters.state = juce::ValueTree::fromXml(*inputXml);
		}
	}
#else
	juce::MemoryInputStream stream(data, static_cast<size_t> (sizeInBytes), false);

	for (int i = 0; i < ids.size(); i++) {
		int id = stream.readInt();
		float idc = parameters.getParameter(ids[i])->convertTo0to1(float(id));
		parameters.getParameter(ids[i])->setValueNotifyingHost(idc);
	}

	std::vector<const char*> ids_radios = { "0x17", "0x1C", "0x11", "0x13", "0x36", "0x22", "0x23", "0x38" };
	for (int i = 0; i < ids_radios.size(); i++) {
		int id = stream.readInt();
		pvalues.set(ids_radios[i], id);
	}

	send_pvalues();
#endif
}

juce::AudioProcessorValueTreeState::ParameterLayout PluginAudioProcessor::createParameterLayout()
{
	using namespace juce;

	std::vector<std::unique_ptr<RangedAudioParameter>> params;

	params.push_back(std::make_unique<AudioParameterInt>("0x19", "osc1_semitone", -12, 12, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x1A", "osc1_detune", 0, 100, 50));
	params.push_back(std::make_unique<AudioParameterInt>("0x1B", "osc1_lfo", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x34", "osc1_pulse", 0, 100, 50));
	params.push_back(std::make_unique<AudioParameterInt>("0x18", "osc1_volume", 0, 100, 100));
	params.push_back(std::make_unique<AudioParameterInt>("0x1E", "osc2_semitone", -12, 12, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x1F", "osc2_detune", 0, 100, 50));
	params.push_back(std::make_unique<AudioParameterInt>("0x20", "osc2_lfo", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x35", "osc2_pulse", 0, 100, 50));
	params.push_back(std::make_unique<AudioParameterInt>("0x1D", "osc2_volume", 0, 100, 100));
	params.push_back(std::make_unique<AudioParameterInt>("0x06", "attack", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x0A", "attack_time", 1, 10, 5));
	params.push_back(std::make_unique<AudioParameterInt>("0x07", "decay", 0, 100, 50));
	params.push_back(std::make_unique<AudioParameterInt>("0x0B", "decay_time", 1, 10, 5));
	params.push_back(std::make_unique<AudioParameterInt>("0x08", "sustain", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x09", "release", 0, 100, 3));
	params.push_back(std::make_unique<AudioParameterInt>("0x0C", "release_time", 1, 10, 5));
	params.push_back(std::make_unique<AudioParameterInt>("0x12", "lfo1_speed", 0, 127, 32));
	params.push_back(std::make_unique<AudioParameterInt>("0x14", "lfo2_speed", 0, 127, 64));
	params.push_back(std::make_unique<AudioParameterInt>("0x37", "lfo3_speed", 0, 127, 10));
	params.push_back(std::make_unique<AudioParameterChoice>("0x39", "lfo3_destination", juce::StringArray{ "FREQUENCY", "FREQUENCY", "RESONANCE", "RESONANCE" }, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x21", "portamento", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x05", "master", 0, 100, 100));
	params.push_back(std::make_unique<AudioParameterInt>("0x0D", "filter_freq", 0, 8000, 8000));
	params.push_back(std::make_unique<AudioParameterInt>("0x0E", "filter_q", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x0F", "filter_lfo", 0, 1, 0));
	params.push_back(std::make_unique<AudioParameterChoice>("0x10", "filter_type", juce::StringArray{ "OFF", "LOW PASS", "HIGH PASS", "BAND PASS", "NOTCH" }, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x15", "noise_volume", 0, 100, 0));
	params.push_back(std::make_unique<AudioParameterInt>("0x16", "pmod_input", 0, 1, 0));

	return { params.begin(), params.end() };
}

// callback for when a parameter is changed
void PluginAudioProcessor::parameterChanged(const juce::String& parameterID, float newValue)
{
	pvalues.set(juce::String(parameterID), newValue);

	if (!connected) return;
	//juce::String v(newValue);
	//juce::File("C:\\test\\filename.txt").appendText("pC: " + parameterID + " " + v +"\r\n");
	DWORD byteswritten = 0;
	int number = (int)strtol(parameterID.toUTF8(), NULL, 0);
	juce::juce_wchar send_data = number;

	switch (number)
	{
	case 25: // 0x19 slider
	case 26: // 0x1A
	case 27: // 0x1B
	case 52: // 0x34
	case 24: // 0x18
	case 30: // 0x1E
	case 31: // 0x1F
	case 32: // 0x20
	case 53: // 0x35
	case 29: // 0x1D
	case 18: // 0x12
	case 20: // 0x14
	case 55: // 0x37
	case 33: // 0x21
	case 5:  // 0x05
	case 13: // 0x0D
	case 14: // 0x0E
	case 15: // 0x0F
	case 21: // 0x15
	case 22: // 0x16
	case 6:	 // 0x06 vSlider
	case 7:	 // 0x07
	case 8:	 // 0x08
	case 9:	 // 0x09
	case 10: // 0x0A hSlider
	case 11: // 0x0B
	case 12: // 0x0C
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		if (number == 13) { // Filter frequency
			int data = (int)newValue;
			send_data = data & 0xFF;
			WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
			send_data = (data >> 8) & 0xFF;
		}
		else {
			send_data = (juce::juce_wchar)newValue;
		}
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		break;
	case 57: // 0x39
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		switch ((int)newValue)
		{
		case 0: // LFO3 FREQUENCY
			send_data = 0x00;
			break;
		case 1: // LFO3 RESONANCE
			send_data = 0x01;
			break;
		default: break;
			break;
		}
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		break;
	case 16: // 0x10
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		switch ((int)newValue)
		{
		case 0: // OFF
			send_data = 0x00;
			break;
		case 1: // LOW PASS FILTER
			send_data = 0x01;
			break;
		case 2: // HIGH PASS FILTER
			send_data = 0x02;
			break;
		case 3: // BAND PASS FILTER
			send_data = 0x03;
			break;
		case 4: // NOTCH FILTER
			send_data = 0x04;
			break;
		default: break;
		}
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		break;
	}
}

void PluginAudioProcessor::update_midicc(int channel, int control)
{
	if (!midi_cc.contains(channel)) {
		std::vector<juce::String> controles(128, "");
		midi_cc.set(channel, controles);
	}
	std::vector<juce::String> ref = midi_cc.getReference(channel);
	ref[control] = sliderId;
	midi_cc.set(channel, ref);

	for (juce::HashMap<int, std::vector<juce::String>>::Iterator i(midi_cc); i.next();) {
		if (channel != i.getKey()) {
			ref = midi_cc.getReference(i.getKey());
			if (ref[lastmidi_cc[sliderId]] == sliderId) {
				ref[lastmidi_cc[sliderId]] = "";
				midi_cc.set(i.getKey(), ref);
			}
		}
	}

	lastmidi_cc.set(sliderId, control);
	write_json_file = true;
}

void PluginAudioProcessor::readJsonFile()
{
	//juce::File json = juce::File::getSpecialLocation(juce::File::currentExecutableFile).getCurrentWorkingDirectory().getFullPathName() + "\\midi.json";
	juce::File json(getCurrentExePath() + "\\midi.json");

	if (!json.existsAsFile())
		return;

	juce::String str_json = json.loadFileAsString();
	juce::var parsedJson;
	if (juce::JSON::parse(str_json, parsedJson).wasOk()) {
		std::vector<const char*> json_params({ "osc1_semitone","osc1_detune","osc1_lfo","osc1_volume","osc1_type",
			"osc2_semitone","osc2_detune","osc2_lfo","osc2_volume","osc2_type","attack","decay","sustain","release",
			"attack_time","decay_time","release_time","lfo1_type","lfo1_speed","lfo1_mode","lfo2_type","lfo2_speed","lfo2_mode",
			"filter_type","filter_freq","filter_res","filter_lfo","noise_volume","noise_tone","portamento","master_volume",
			"osc1_pulse","osc2_pulse","lfo3_type","lfo3_speed","lfo3_mode","lfo3_destination" });

		std::vector<const char*> json_id({ "0x19", "0x1A", "0x1B", "0x18", "0x17", "0x1E", "0x1F", "0x20", "0x1D", "0x1C",
			"0x06", "0x07", "0x08", "0x09", "0x0A", "0x0B", "0x0C", "0x11", "0x12", "0x22", "0x13", "0x14", "0x23", "0x10",
			"0x0D", "0x0E", "0x0F", "0x15", "0x16", "0x21", "0x05", "0x34", "0x35", "0x36", "0x37", "0x38", "0x39" });

		std::vector<juce::String> controles(128, "");

		for (int i = 0; i < json_params.size(); i++) {
			int channel = parsedJson[json_params[i]]["channel"];
			if (!midi_cc.contains(channel)) {
				midi_cc.set(channel, controles);
			}
			std::vector<juce::String> ref = midi_cc.getReference(channel);
			int control = parsedJson[json_params[i]]["control"];
			ref[control] = json_id[i];
			lastmidi_cc.set(json_id[i], control);
			midi_cc.set(channel, ref);
		}
	}
}

void PluginAudioProcessor::write_json()
{
	std::vector<const char*> json_params({ "osc1_semitone","osc1_detune","osc1_lfo","osc1_volume","osc1_type",
			"osc2_semitone","osc2_detune","osc2_lfo","osc2_volume","osc2_type","attack","decay","sustain","release",
			"attack_time","decay_time","release_time","lfo1_type","lfo1_speed","lfo1_mode","lfo2_type","lfo2_speed","lfo2_mode",
			"filter_type","filter_freq","filter_res","filter_lfo","noise_volume","noise_tone","portamento","master_volume",
			"osc1_pulse","osc2_pulse","lfo3_type","lfo3_speed","lfo3_mode","lfo3_destination" });

	std::vector<const char*> json_id({ "0x19", "0x1A", "0x1B", "0x18", "0x17", "0x1E", "0x1F", "0x20", "0x1D", "0x1C",
		"0x06", "0x07", "0x08", "0x09", "0x0A", "0x0B", "0x0C", "0x11", "0x12", "0x22", "0x13", "0x14", "0x23", "0x10",
		"0x0D", "0x0E", "0x0F", "0x15", "0x16", "0x21", "0x05", "0x34", "0x35", "0x36", "0x37", "0x38", "0x39" });

	juce::HashMap<juce::String, int> id_param;
	for (int i = 0; i < json_params.size(); i++) {
		id_param.set(json_id[i], i);
	}

	juce::DynamicObject* obj = new juce::DynamicObject();
	for (juce::HashMap<int, std::vector<juce::String>>::Iterator i(midi_cc); i.next();) {
		std::vector<juce::String> s = midi_cc.getReference(i.getKey());
		for (int a = 0; a < s.size(); a++) {
			if (s[a] != "") {
				juce::DynamicObject* nestedObj = new juce::DynamicObject();
				nestedObj->setProperty("channel", i.getKey());
				nestedObj->setProperty("control", a);
				obj->setProperty(json_params[id_param[s[a]]], nestedObj);
			}
		}
	}
	obj->setProperty("disabled", false);
	juce::var json(obj);
	//juce::String s = juce::JSON::toString(json);
	//juce::File("C:\\test\\filename.txt").appendText(" " + juce::String(s) + "\r\n");

	//juce::File file = juce::File::getSpecialLocation(juce::File::currentExecutableFile).getCurrentWorkingDirectory().getFullPathName() + "\\midi.json";
	juce::File file(getCurrentExePath() + "\\midi.json");
	juce::FileOutputStream stream(file);
	if (stream.openedOk())
	{
		stream.setPosition(0);
		stream.truncate();
		juce::JSON::writeToStream(stream, json);
	}
}

void PluginAudioProcessor::setParamValue(int data, juce::NotificationType notification)
{
	juce::Slider* sl;
	juce::Button* button;
	juce::ComboBox* combo;

	switch (state)
	{
	case PORTAMENTO:
		sl = (juce::Slider*)midi_comp["0x21"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case MASTER_VOLUME:
		sl = (juce::Slider*)midi_comp["0x05"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case ATTACK:
		sl = (juce::Slider*)midi_comp["0x06"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case DECAY:
		sl = (juce::Slider*)midi_comp["0x07"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case SUSTAIN:
		sl = (juce::Slider*)midi_comp["0x08"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case RELEASE:
		sl = (juce::Slider*)midi_comp["0x09"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case ATTACK_TIME:
		sl = (juce::Slider*)midi_comp["0x0A"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case DECAY_TIME:
		sl = (juce::Slider*)midi_comp["0x0B"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case RELEASE_TIME:
		sl = (juce::Slider*)midi_comp["0x0C"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case FILTER_FREQ_B0:
		filter_freq_b0 = data;
		state = FILTER_FREQ_B1;
		break;
	case FILTER_FREQ_B1:
		sl = (juce::Slider*)midi_comp["0x0D"].first;
		sl->setValue(data * 256 + filter_freq_b0, notification);
		state = INITIAL;
		break;
	case FILTER_Q:
		sl = (juce::Slider*)midi_comp["0x0E"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case FILTER_LFO:
		sl = (juce::Slider*)midi_comp["0x0F"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case FILTER_TYPE:
		combo = (juce::ComboBox*)midi_comp["0x10"].first;
		combo->setSelectedItemIndex(data, notification);
		state = INITIAL;
		break;
	case LFO1_TYPE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x11a"].first;
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x11b"].first;
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x11c"].first;
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x11d"].first;
			break;
		}
		button->setToggleState(true, notification);
		state = INITIAL;
		break;
	case LFO1_SPEED:
		sl = (juce::Slider*)midi_comp["0x12"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case LFO2_TYPE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x13a"].first;
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x13b"].first;
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x13c"].first;
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x13d"].first;
			break;
		}
		button->setToggleState(true, notification);
		state = INITIAL;
		break;
	case LFO2_SPEED:
		sl = (juce::Slider*)midi_comp["0x14"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case LFO3_TYPE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x36a"].first;
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x36b"].first;
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x36c"].first;
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x36d"].first;
			break;
		}
		button->setToggleState(true, notification);
		state = INITIAL;
		break;
	case LFO3_SPEED:
		sl = (juce::Slider*)midi_comp["0x37"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case LFO3_DESTINATION:
		combo = (juce::ComboBox*)midi_comp["0x39"].first;
		combo->setSelectedItemIndex(data, notification);
		state = INITIAL;
		break;
	case NOISE_VOLUME:
		sl = (juce::Slider*)midi_comp["0x15"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case PMOD_INPUT:
		sl = (juce::Slider*)midi_comp["0x16"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC1_TYPE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x17a"].first;
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x17b"].first;
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x17c"].first;
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x17d"].first;
			break;
		}
		button->setToggleState(true, notification);
		state = INITIAL;
		break;
	case OSC1_VOLUME:
		sl = (juce::Slider*)midi_comp["0x18"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC1_SEMITONE:
		sl = (juce::Slider*)midi_comp["0x19"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC1_DETUNE:
		sl = (juce::Slider*)midi_comp["0x1A"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC1_LFO:
		sl = (juce::Slider*)midi_comp["0x1B"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC1_PULSE:
		sl = (juce::Slider*)midi_comp["0x34"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC2_TYPE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x1Ca"].first;
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x1Cb"].first;
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x1Cc"].first;
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x1Cd"].first;
			break;
		}
		button->setToggleState(true, notification);
		state = INITIAL;
		break;
	case OSC2_VOLUME:
		sl = (juce::Slider*)midi_comp["0x1D"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC2_SEMITONE:
		sl = (juce::Slider*)midi_comp["0x1E"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC2_DETUNE:
		sl = (juce::Slider*)midi_comp["0x1F"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC2_LFO:
		sl = (juce::Slider*)midi_comp["0x20"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case OSC2_PULSE:
		sl = (juce::Slider*)midi_comp["0x35"].first;
		sl->setValue(data, notification);
		state = INITIAL;
		break;
	case LFO1_MODE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x22a"].first;
			lfoUpdateMode(0x22, 0x00);
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x22a"].first;
			lfoUpdateMode(0x22, 0x01);
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x22b"].first;
			lfoUpdateMode(0x22, 0x02);
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x22b"].first;
			lfoUpdateMode(0x22, 0x03);
			break;
		}
		button->setButtonText(juce::String(data + 1));
		button->setToggleState(true, juce::dontSendNotification);
		state = INITIAL;
		break;
	case LFO2_MODE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x23a"].first;
			lfoUpdateMode(0x23, 0x00);
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x23a"].first;
			lfoUpdateMode(0x23, 0x01);
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x23b"].first;
			lfoUpdateMode(0x23, 0x02);
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x23b"].first;
			lfoUpdateMode(0x23, 0x03);
			break;
		}
		button->setButtonText(juce::String(data + 1));
		button->setToggleState(true, juce::dontSendNotification);
		state = INITIAL;
		break;
	case LFO3_MODE:
		switch (data)
		{
		case 0x00:
			button = (juce::Button*)midi_comp["0x38a"].first;
			lfoUpdateMode(0x38, 0x00);
			break;
		case 0x01:
			button = (juce::Button*)midi_comp["0x38a"].first;
			lfoUpdateMode(0x38, 0x01);
			break;
		case 0x02:
			button = (juce::Button*)midi_comp["0x38b"].first;
			lfoUpdateMode(0x38, 0x02);
			break;
		case 0x03:
			button = (juce::Button*)midi_comp["0x38b"].first;
			lfoUpdateMode(0x38, 0x03);
			break;
		}
		button->setButtonText(juce::String(data + 1));
		button->setToggleState(true, juce::dontSendNotification);
		state = INITIAL;
		break;
	case INITIAL:
		switch (data)
		{
		case 0x05:
			state = MASTER_VOLUME;
			break;
		case 0x06:
			state = ATTACK;
			break;
		case 0x07:
			state = DECAY;
			break;
		case 0x08:
			state = SUSTAIN;
			break;
		case 0x09:
			state = RELEASE;
			break;
		case 0x0A:
			state = ATTACK_TIME;
			break;
		case 0x0B:
			state = DECAY_TIME;
			break;
		case 0x0C:
			state = RELEASE_TIME;
			break;
		case 0x0D:
			state = FILTER_FREQ_B0;
			break;
		case 0x0E:
			state = FILTER_Q;
			break;
		case 0x0F:
			state = FILTER_LFO;
			break;
		case 0x10:
			state = FILTER_TYPE;
			break;
		case 0x11:
			state = LFO1_TYPE;
			break;
		case 0x12:
			state = LFO1_SPEED;
			break;
		case 0x13:
			state = LFO2_TYPE;
			break;
		case 0x14:
			state = LFO2_SPEED;
			break;
		case 0x15:
			state = NOISE_VOLUME;
			break;
		case 0x16:
			state = PMOD_INPUT;
			break;
		case 0x17:
			state = OSC1_TYPE;
			break;
		case 0x18:
			state = OSC1_VOLUME;
			break;
		case 0x19:
			state = OSC1_SEMITONE;
			break;
		case 0x1A:
			state = OSC1_DETUNE;
			break;
		case 0x1B:
			state = OSC1_LFO;
			break;
		case 0x1C:
			state = OSC2_TYPE;
			break;
		case 0x1D:
			state = OSC2_VOLUME;
			break;
		case 0x1E:
			state = OSC2_SEMITONE;
			break;
		case 0x1F:
			state = OSC2_DETUNE;
			break;
		case 0x20:
			state = OSC2_LFO;
			break;
		case 0x21:
			state = PORTAMENTO;
			break;
		case 0x22:
			state = LFO1_MODE;
			break;
		case 0x23:
			state = LFO2_MODE;
			break;
		case 0x34:
			state = OSC1_PULSE;
			break;
		case 0x35:
			state = OSC2_PULSE;
			break;
		case 0x36:
			state = LFO3_TYPE;
			break;
		case 0x37:
			state = LFO3_SPEED;
			break;
		case 0x38:
			state = LFO3_MODE;
			break;
		case 0x39:
			state = LFO3_DESTINATION;
			break;
		default:
			state = INITIAL;
		}
		break;
	}
}

void PluginAudioProcessor::lfoUpdateMode(juce::juce_wchar param, juce::juce_wchar value)
{
	if (!connected) return;
	DWORD byteswritten = 0;
	WriteFile(hComm, &param, 1, &byteswritten, NULL);
	WriteFile(hComm, &value, 1, &byteswritten, NULL);
}

void PluginAudioProcessor::initParametersValue()
{
	pvalues.set(juce::String("0x17"), 0);
	pvalues.set(juce::String("0x19"), 0);
	pvalues.set(juce::String("0x1A"), 50);
	pvalues.set(juce::String("0x1B"), 0);
	pvalues.set(juce::String("0x34"), 50);
	pvalues.set(juce::String("0x18"), 100);
	pvalues.set(juce::String("0x1C"), 0);
	pvalues.set(juce::String("0x1E"), 0);
	pvalues.set(juce::String("0x1F"), 50);
	pvalues.set(juce::String("0x20"), 0);
	pvalues.set(juce::String("0x35"), 50);
	pvalues.set(juce::String("0x1D"), 100);
	pvalues.set(juce::String("0x06"), 0);
	pvalues.set(juce::String("0x0A"), 5);
	pvalues.set(juce::String("0x07"), 50);
	pvalues.set(juce::String("0x0B"), 5);
	pvalues.set(juce::String("0x08"), 0);
	pvalues.set(juce::String("0x09"), 3);
	pvalues.set(juce::String("0x0C"), 5);
	pvalues.set(juce::String("0x11"), 0);
	pvalues.set(juce::String("0x12"), 32);
	pvalues.set(juce::String("0x22"), 0);
	pvalues.set(juce::String("0x13"), 0);
	pvalues.set(juce::String("0x14"), 64);
	pvalues.set(juce::String("0x23"), 0);
	pvalues.set(juce::String("0x36"), 0);
	pvalues.set(juce::String("0x37"), 10);
	pvalues.set(juce::String("0x38"), 0);
	pvalues.set(juce::String("0x39"), 0);
	pvalues.set(juce::String("0x21"), 0);
	pvalues.set(juce::String("0x05"), 100);
	pvalues.set(juce::String("0x0D"), 8000);
	pvalues.set(juce::String("0x0E"), 2);
	pvalues.set(juce::String("0x0F"), 0);
	pvalues.set(juce::String("0x10"), 0);
	pvalues.set(juce::String("0x15"), 0);
	pvalues.set(juce::String("0x16"), 0);
}

#if !STANDALONE
void PluginAudioProcessor::send_pvalues()
{
	// send pvalues data
	DWORD byteswritten = 0;
	for (juce::HashMap<juce::String, int>::Iterator i(pvalues); i.next();) {
		int param = (int)strtol(i.getKey().toUTF8(), NULL, 0);
		juce::juce_wchar send_data = param;
		WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		if (param == 13) { // 0x0D, filter freq
			int data = pvalues.getReference(i.getKey());
			send_data = data & 0xFF;
			WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
			send_data = (data >> 8) & 0xFF;
			WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		}
		else {
			send_data = pvalues.getReference(i.getKey());
			WriteFile(hComm, &send_data, 1, &byteswritten, NULL);
		}
		//juce::File("C:\\test\\filename.txt").appendText(juce::String(param) + "\t" + juce::String(send_data) + "\n");
	}
}
#endif

juce::String PluginAudioProcessor::getCurrentExePath()
{
	int pos = juce::File::getSpecialLocation(juce::File::currentExecutableFile).getFullPathName().lastIndexOf("\\");
	juce::String path(juce::File::getSpecialLocation(juce::File::currentExecutableFile).getFullPathName().substring(0, pos));
	return path;
}

bool PluginAudioProcessor::readIniFile()
{
	juce::File file(getCurrentExePath() + "\\settings.ini");
	if (!file.existsAsFile())
		return false; // file doesn't exist

	juce::FileInputStream inputStream(file);

	if (!inputStream.openedOk())
		return false; // failed to open

	com_port_value = inputStream.readNextLine();
	return true;
}