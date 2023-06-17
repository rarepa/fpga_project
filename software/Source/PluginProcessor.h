/*
  ==============================================================================

	This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include <windows.h>
#include <JuceHeader.h>

#define STANDALONE true
//#define STANDALONE false

//==============================================================================
/**
*/

class PluginAudioProcessor : public juce::AudioProcessor
#if JucePlugin_Enable_ARA
	, public juce::AudioProcessorARAExtension
#endif
	, public juce::AudioProcessorValueTreeState::Listener
{
public:
	//==============================================================================
	PluginAudioProcessor();
	~PluginAudioProcessor() override;

	HANDLE hComm;
	juce::String com_port_value;
	bool connected;
	bool learning = false;
	juce::String sliderId = "";
	juce::HashMap<juce::String, std::pair<juce::Component*, int>> midi_comp;
	juce::HashMap<juce::String, int> pvalues;
	juce::String getCurrentExePath();

	//==============================================================================
	void prepareToPlay(double sampleRate, int samplesPerBlock) override;
	void releaseResources() override;

#ifndef JucePlugin_PreferredChannelConfigurations
	bool isBusesLayoutSupported(const BusesLayout& layouts) const override;
#endif

	void processBlock(juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

	//==============================================================================
	juce::AudioProcessorEditor* createEditor() override;
	bool hasEditor() const override;

	//==============================================================================
	const juce::String getName() const override;

	bool acceptsMidi() const override;
	bool producesMidi() const override;
	bool isMidiEffect() const override;
	double getTailLengthSeconds() const override;

	//==============================================================================
	int getNumPrograms() override;
	int getCurrentProgram() override;
	void setCurrentProgram(int index) override;
	const juce::String getProgramName(int index) override;
	void changeProgramName(int index, const juce::String& newName) override;

	//==============================================================================
	void getStateInformation(juce::MemoryBlock& destData) override;
	void setStateInformation(const void* data, int sizeInBytes) override;

	// callback for when a parameter is changed, inherited from vts listener
	void parameterChanged(const juce::String& parameterID, float newValue) override;

	void FPGA_Connection();
	void update_midicc(int channel, int control);
	void setParamValue(int data, juce::NotificationType notification);

	juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

	enum param_state {
		INITIAL, PORTAMENTO, MASTER_VOLUME,
		ATTACK, DECAY, SUSTAIN, RELEASE, ATTACK_TIME, DECAY_TIME, RELEASE_TIME,
		FILTER_FREQ_B0, FILTER_FREQ_B1, FILTER_Q, FILTER_LFO, FILTER_TYPE,
		LFO1_TYPE, LFO1_SPEED, LFO2_TYPE, LFO2_SPEED, NOISE_VOLUME, PMOD_INPUT,
		OSC1_TYPE, OSC1_VOLUME, OSC1_SEMITONE, OSC1_DETUNE, OSC1_LFO, OSC1_PULSE,
		OSC2_TYPE, OSC2_VOLUME, OSC2_SEMITONE, OSC2_DETUNE, OSC2_LFO, OSC2_PULSE,
		LFO1_MODE, LFO2_MODE, LFO3_TYPE, LFO3_SPEED, LFO3_MODE, LFO3_DESTINATION
	};

	param_state state;

private:
	//==============================================================================
	juce::AudioProcessorValueTreeState parameters;
	juce::HashMap<juce::String, int> lastmidi_cc;
	juce::HashMap<int, std::vector<juce::String>> midi_cc;
	int filter_freq_b0;
	bool write_json_file;
	void readJsonFile();
	void write_json();
	void lfoUpdateMode(juce::juce_wchar param, juce::juce_wchar value);
	void initParametersValue();
	bool readIniFile();
#if !STANDALONE
	void send_pvalues();
#endif

	std::vector<const char*> ids;

	JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PluginAudioProcessor)
};
