#pragma once
#include <windows.h>
#include <JuceHeader.h>
#include "PluginEditor.h"

//int controls = ((grup_radios + round_sliders + vertical_sliders + horizontal_sliders + labels(radio-lfo) + combos) * 2) + round_slider
#define controls ((5 + 19 + 4 + 3 + 3 + 2) * 2) + (1 * 3)

class MainComponent : public juce::Component
#if STANDALONE
	, public juce::KeyListener, public juce::Timer
#endif
{
public:
	class BasicWindow : public juce::DocumentWindow
	{
	public:
		BasicWindow(const juce::String& name, juce::Colour backgroundColour, int buttonsNeeded, MainComponent* mainComponent)
			: DocumentWindow(name, backgroundColour, buttonsNeeded)
		{
			mc = mainComponent;
			setContentOwned(new Tabla(mainComponent), false);
			setTitleBarButtonsRequired(DocumentWindow::TitleBarButtons::closeButton +
				DocumentWindow::TitleBarButtons::minimiseButton, false);
		}

		void closeButtonPressed() override
		{
			mc->basicWindow = nullptr;
			delete this;
		}

	private:
		MainComponent* mc;
		JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(BasicWindow)
	};

	std::vector<std::pair<juce::Component*, int>> vComponents; // component, type
	BasicWindow* basicWindow;
	PluginAudioProcessor* audioProcessor;

	MainComponent(juce::AudioProcessorValueTreeState& vts, PluginAudioProcessor* p) : parameters(vts)
	{
		basicWindow = nullptr;

		audioProcessor = p;
#if STANDALONE
		addKeyListener(this);
		startTimer(10);
#endif

		// OSCILLATOR1 GROUP
		addAndMakeVisible(osc1_group);
		osc1_group.setText("OSCILLATOR1");
		osc1_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(osc1_saw);
		vComponents.push_back(std::make_pair(&osc1_saw, 1));
		addAndMakeVisible(osc1_tri);
		vComponents.push_back(std::make_pair(&osc1_tri, 1));
		addAndMakeVisible(osc1_squ);
		vComponents.push_back(std::make_pair(&osc1_squ, 1));
		addAndMakeVisible(osc1_sin);
		vComponents.push_back(std::make_pair(&osc1_sin, 1));
		osc1_saw.setComponentID("0x17");
		osc1_saw.setName("0");
		audioProcessor->midi_comp.set("0x17a", std::make_pair(&osc1_saw, 1));
		osc1_saw.setRadioGroupId(100);
		osc1_saw.onClick = [this] { WaveTypeChanged(&osc1_saw, "0"); };
		osc1_tri.setComponentID("0x17");
		osc1_tri.setName("1");
		audioProcessor->midi_comp.set("0x17b", std::make_pair(&osc1_tri, 1));
		osc1_tri.setRadioGroupId(100);
		osc1_tri.onClick = [this] { WaveTypeChanged(&osc1_tri, "1"); };
		osc1_squ.setComponentID("0x17");
		osc1_squ.setName("2");
		audioProcessor->midi_comp.set("0x17c", std::make_pair(&osc1_squ, 1));
		osc1_squ.setRadioGroupId(100);
		osc1_squ.onClick = [this] { WaveTypeChanged(&osc1_squ, "2"); };
		osc1_sin.setComponentID("0x17");
		osc1_sin.setName("3");
		audioProcessor->midi_comp.set("0x17d", std::make_pair(&osc1_sin, 1));
		osc1_sin.setRadioGroupId(100);
		osc1_sin.onClick = [this] { WaveTypeChanged(&osc1_sin, "3"); };

		if (audioProcessor->pvalues["0x17"] == 3) {
			osc1_sin.setToggleState(true, juce::dontSendNotification);
			osc1_value = "3";
		}
		else if (audioProcessor->pvalues["0x17"] == 2) {
			osc1_squ.setToggleState(true, juce::dontSendNotification);
			osc1_value = "2";
		}
		else if (audioProcessor->pvalues["0x17"] == 1) {
			osc1_tri.setToggleState(true, juce::dontSendNotification);
			osc1_value = "1";
		}
		else {
			osc1_saw.setToggleState(true, juce::dontSendNotification);
			osc1_value = "0";
		}

		addAndMakeVisible(osc1_semitone);
		vComponents.push_back(std::make_pair(&osc1_semitone, 2));
		audioProcessor->midi_comp.set("0x19", std::make_pair(&osc1_semitone, 2));
		osc1_semitone.setComponentID("0x19");
		osc1_semitone_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x19", osc1_semitone));
		osc1_semitone.setValue(audioProcessor->pvalues["0x19"], juce::sendNotification);
		osc1_semitone.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc1_semitone.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc1_semitone.setTextBoxIsEditable(true);
		osc1_semitone.mc = this;

		addAndMakeVisible(osc1_semitone_label);
		osc1_semitone_label.setText("SEMITONE", juce::dontSendNotification);
		osc1_semitone_label.attachToComponent(&osc1_semitone, false);
		osc1_semitone_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc1_semitone_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc1_detune);
		vComponents.push_back(std::make_pair(&osc1_detune, 2));
		audioProcessor->midi_comp.set("0x1A", std::make_pair(&osc1_detune, 2));
		osc1_detune.setComponentID("0x1A");
		osc1_detune_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x1A", osc1_detune));
		osc1_detune.setValue(audioProcessor->pvalues["0x1A"], juce::sendNotification);
		osc1_detune.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc1_detune.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc1_detune.setTextBoxIsEditable(true);
		osc1_detune.mc = this;

		addAndMakeVisible(osc1_detune_label);
		osc1_detune_label.setText("DETUNE", juce::dontSendNotification);
		osc1_detune_label.attachToComponent(&osc1_detune, true);
		osc1_detune_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc1_detune_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc1_lfo);
		vComponents.push_back(std::make_pair(&osc1_lfo, 2));
		audioProcessor->midi_comp.set("0x1B", std::make_pair(&osc1_lfo, 2));
		osc1_lfo.setComponentID("0x1B");
		osc1_lfo_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x1B", osc1_lfo));
		osc1_lfo.setValue(audioProcessor->pvalues["0x1B"], juce::sendNotification);
		osc1_lfo.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc1_lfo.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc1_lfo.setTextBoxIsEditable(true);
		osc1_lfo.mc = this;

		addAndMakeVisible(osc1_lfo_label);
		osc1_lfo_label.setText("LFO1", juce::dontSendNotification);
		osc1_lfo_label.attachToComponent(&osc1_lfo, true);
		osc1_lfo_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc1_lfo_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc1_pulse);
		vComponents.push_back(std::make_pair(&osc1_pulse, 2));
		audioProcessor->midi_comp.set("0x34", std::make_pair(&osc1_pulse, 2));
		osc1_pulse.setComponentID("0x34");
		osc1_pulse_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x34", osc1_pulse));
		osc1_pulse.setValue(audioProcessor->pvalues["0x34"], juce::sendNotification);
		osc1_pulse.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc1_pulse.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc1_pulse.setTextBoxIsEditable(true);
		osc1_pulse.mc = this;

		addAndMakeVisible(osc1_pulse_label);
		osc1_pulse_label.setText("PULSE WIDTH", juce::dontSendNotification);
		osc1_pulse_label.attachToComponent(&osc1_pulse, true);
		osc1_pulse_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc1_pulse_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc1_volume);
		vComponents.push_back(std::make_pair(&osc1_volume, 2));
		audioProcessor->midi_comp.set("0x18", std::make_pair(&osc1_volume, 2));
		osc1_volume.setComponentID("0x18");
		osc1_volume_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x18", osc1_volume));
		osc1_volume.setValue(audioProcessor->pvalues["0x18"], juce::sendNotification);
		osc1_volume.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc1_volume.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc1_volume.setTextBoxIsEditable(true);
		osc1_volume.mc = this;

		addAndMakeVisible(osc1_volume_label);
		osc1_volume_label.setText("VOLUME", juce::dontSendNotification);
		osc1_volume_label.attachToComponent(&osc1_volume, true);
		osc1_volume_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc1_volume_label.setJustificationType(juce::Justification::centred);

		// OSCILLATOR2 GROUP
		addAndMakeVisible(osc2_group);
		osc2_group.setText("OSCILLATOR2");
		osc2_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(osc2_saw);
		vComponents.push_back(std::make_pair(&osc2_saw, 1));
		addAndMakeVisible(osc2_tri);
		vComponents.push_back(std::make_pair(&osc2_tri, 1));
		addAndMakeVisible(osc2_squ);
		vComponents.push_back(std::make_pair(&osc2_squ, 1));
		addAndMakeVisible(osc2_sin);
		vComponents.push_back(std::make_pair(&osc2_sin, 1));
		osc2_saw.setComponentID("0x1C");
		osc2_saw.setName("0");
		audioProcessor->midi_comp.set("0x1Ca", std::make_pair(&osc2_saw, 1));
		osc2_saw.setRadioGroupId(200);
		osc2_saw.setToggleState(true, juce::dontSendNotification);
		osc2_saw.onClick = [this] { WaveTypeChanged(&osc2_saw, "0"); };
		osc2_tri.setComponentID("0x1C");
		osc2_tri.setName("1");
		audioProcessor->midi_comp.set("0x1Cb", std::make_pair(&osc2_tri, 1));
		osc2_tri.setRadioGroupId(200);
		osc2_tri.onClick = [this] { WaveTypeChanged(&osc2_tri, "1"); };
		osc2_squ.setComponentID("0x1C");
		osc2_squ.setName("2");
		audioProcessor->midi_comp.set("0x1Cc", std::make_pair(&osc2_squ, 1));
		osc2_squ.setRadioGroupId(200);
		osc2_squ.onClick = [this] { WaveTypeChanged(&osc2_squ, "2"); };
		osc2_sin.setComponentID("0x1C");
		osc2_sin.setName("3");
		audioProcessor->midi_comp.set("0x1Cd", std::make_pair(&osc2_sin, 1));
		osc2_sin.setRadioGroupId(200);
		osc2_sin.onClick = [this] { WaveTypeChanged(&osc2_sin, "3"); };

		if (audioProcessor->pvalues["0x1C"] == 3) {
			osc2_sin.setToggleState(true, juce::dontSendNotification);
			osc2_value = "3";
		}
		else if (audioProcessor->pvalues["0x1C"] == 2) {
			osc2_squ.setToggleState(true, juce::dontSendNotification);
			osc2_value = "2";
		}
		else if (audioProcessor->pvalues["0x1C"] == 1) {
			osc2_tri.setToggleState(true, juce::dontSendNotification);
			osc2_value = "1";
		}
		else {
			osc2_saw.setToggleState(true, juce::dontSendNotification);
			osc2_value = "0";
		}

		addAndMakeVisible(osc2_semitone);
		vComponents.push_back(std::make_pair(&osc2_semitone, 2));
		audioProcessor->midi_comp.set("0x1E", std::make_pair(&osc2_semitone, 2));
		osc2_semitone.setComponentID("0x1E");
		osc2_semitone_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x1E", osc2_semitone));
		osc2_semitone.setValue(audioProcessor->pvalues["0x1E"], juce::sendNotification);
		osc2_semitone.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc2_semitone.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc2_semitone.setTextBoxIsEditable(true);
		osc2_semitone.mc = this;

		addAndMakeVisible(osc2_semitone_label);
		osc2_semitone_label.setText("SEMITONE", juce::dontSendNotification);
		osc2_semitone_label.attachToComponent(&osc2_semitone, true);
		osc2_semitone_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc2_semitone_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc2_detune);
		vComponents.push_back(std::make_pair(&osc2_detune, 2));
		audioProcessor->midi_comp.set("0x1F", std::make_pair(&osc2_detune, 2));
		osc2_detune.setComponentID("0x1F");
		osc2_detune_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x1F", osc2_detune));
		osc2_detune.setValue(audioProcessor->pvalues["0x1F"], juce::sendNotification);
		osc2_detune.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc2_detune.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc2_detune.setTextBoxIsEditable(true);
		osc2_detune.mc = this;

		addAndMakeVisible(osc2_detune_label);
		osc2_detune_label.setText("DETUNE", juce::dontSendNotification);
		osc2_detune_label.attachToComponent(&osc2_detune, true);
		osc2_detune_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc2_detune_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc2_lfo);
		vComponents.push_back(std::make_pair(&osc2_lfo, 2));
		audioProcessor->midi_comp.set("0x20", std::make_pair(&osc2_lfo, 2));
		osc2_lfo.setComponentID("0x20");
		osc2_lfo_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x20", osc2_lfo));
		osc2_lfo.setValue(audioProcessor->pvalues["0x20"], juce::sendNotification);
		osc2_lfo.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc2_lfo.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc2_lfo.setTextBoxIsEditable(true);
		osc2_lfo.mc = this;

		addAndMakeVisible(osc2_lfo_label);
		osc2_lfo_label.setText("LFO2", juce::dontSendNotification);
		osc2_lfo_label.attachToComponent(&osc2_lfo, true);
		osc2_lfo_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc2_lfo_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc2_pulse);
		vComponents.push_back(std::make_pair(&osc2_pulse, 2));
		audioProcessor->midi_comp.set("0x35", std::make_pair(&osc2_pulse, 2));
		osc2_pulse.setComponentID("0x35");
		osc2_pulse_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x35", osc2_pulse));
		osc2_pulse.setValue(audioProcessor->pvalues["0x35"], juce::sendNotification);
		osc2_pulse.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc2_pulse.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc2_pulse.setTextBoxIsEditable(true);
		osc2_pulse.mc = this;

		addAndMakeVisible(osc2_pulse_label);
		osc2_pulse_label.setText("PULSE WIDTH", juce::dontSendNotification);
		osc2_pulse_label.attachToComponent(&osc2_pulse, true);
		osc2_pulse_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc2_pulse_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(osc2_volume);
		vComponents.push_back(std::make_pair(&osc2_volume, 2));
		audioProcessor->midi_comp.set("0x1D", std::make_pair(&osc2_volume, 2));
		osc2_volume.setComponentID("0x1D");
		osc2_volume_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x1D", osc2_volume));
		osc2_volume.setValue(audioProcessor->pvalues["0x1D"], juce::sendNotification);
		osc2_volume.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		osc2_volume.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		osc2_volume.setTextBoxIsEditable(true);
		osc2_volume.mc = this;

		addAndMakeVisible(osc2_volume_label);
		osc2_volume_label.setText("VOLUME", juce::dontSendNotification);
		osc2_volume_label.attachToComponent(&osc2_volume, true);
		osc2_volume_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		osc2_volume_label.setJustificationType(juce::Justification::centred);

		// AMPLITUDE ENVELOPE GROUP
		addAndMakeVisible(amp_env_group);
		amp_env_group.setText("AMPLITUDE ENVELOPE");
		amp_env_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(attack);
		vComponents.push_back(std::make_pair(&attack, 2));
		audioProcessor->midi_comp.set("0x06", std::make_pair(&attack, 2));
		attack.setComponentID("0x06");
		attack_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x06", attack));
		attack.setValue(audioProcessor->pvalues["0x06"], juce::sendNotification);
		attack.setSliderStyle(juce::Slider::SliderStyle::LinearVertical);
		attack.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		attack.setTextBoxIsEditable(true);
		attack.mc = this;

		addAndMakeVisible(attack_label);
		attack_label.setText("ATTACK", juce::dontSendNotification);
		attack_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		attack_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(attack_time);
		vComponents.push_back(std::make_pair(&attack_time, 2));
		audioProcessor->midi_comp.set("0x0A", std::make_pair(&attack_time, 2));
		attack_time.setComponentID("0x0A");
		attack_time_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x0A", attack_time));
		attack_time.setValue(audioProcessor->pvalues["0x0A"], juce::sendNotification);
		attack_time.setSliderStyle(juce::Slider::SliderStyle::LinearHorizontal);
		attack_time.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		attack_time.setTextBoxIsEditable(true);
		attack_time.mc = this;

		addAndMakeVisible(decay);
		vComponents.push_back(std::make_pair(&decay, 2));
		audioProcessor->midi_comp.set("0x07", std::make_pair(&decay, 2));
		decay.setComponentID("0x07");
		decay_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x07", decay));
		decay.setValue(audioProcessor->pvalues["0x07"], juce::sendNotification);
		decay.setSliderStyle(juce::Slider::SliderStyle::LinearVertical);
		decay.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		decay.setTextBoxIsEditable(true);
		decay.mc = this;

		addAndMakeVisible(decay_label);
		decay_label.setText("DECAY", juce::dontSendNotification);
		decay_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		decay_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(decay_time);
		vComponents.push_back(std::make_pair(&decay_time, 2));
		audioProcessor->midi_comp.set("0x0B", std::make_pair(&decay_time, 2));
		decay_time.setComponentID("0x0B");
		decay_time_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x0B", decay_time));
		decay_time.setValue(audioProcessor->pvalues["0x0B"], juce::sendNotification);
		decay_time.setSliderStyle(juce::Slider::SliderStyle::LinearHorizontal);
		decay_time.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		decay_time.setTextBoxIsEditable(true);
		decay_time.mc = this;

		addAndMakeVisible(sustain);
		vComponents.push_back(std::make_pair(&sustain, 2));
		audioProcessor->midi_comp.set("0x08", std::make_pair(&sustain, 2));
		sustain.setComponentID("0x08");
		sustain_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x08", sustain));
		sustain.setValue(audioProcessor->pvalues["0x08"], juce::sendNotification);
		sustain.setSliderStyle(juce::Slider::SliderStyle::LinearVertical);
		sustain.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		sustain.setTextBoxIsEditable(true);
		sustain.mc = this;

		addAndMakeVisible(sustain_label);
		sustain_label.setText("SUSTAIN", juce::dontSendNotification);
		sustain_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		sustain_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(sustain_time);
		sustain_time.setText("-", juce::dontSendNotification);
		sustain_time.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		sustain_time.setColour(juce::Label::textColourId, juce::Colours::white);
		sustain_time.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(release);
		vComponents.push_back(std::make_pair(&release, 2));
		audioProcessor->midi_comp.set("0x09", std::make_pair(&release, 2));
		release.setComponentID("0x09");
		release_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x09", release));
		release.setValue(audioProcessor->pvalues["0x09"], juce::sendNotification);
		release.setSliderStyle(juce::Slider::SliderStyle::LinearVertical);
		release.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		release.setTextBoxIsEditable(true);
		release.mc = this;

		addAndMakeVisible(release_label);
		release_label.setText("RELEASE", juce::dontSendNotification);
		release_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		release_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(release_time);
		vComponents.push_back(std::make_pair(&release_time, 2));
		audioProcessor->midi_comp.set("0x0C", std::make_pair(&release_time, 2));
		release_time.setComponentID("0x0C");
		release_time_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x0C", release_time));
		release_time.setValue(audioProcessor->pvalues["0x0C"], juce::sendNotification);
		release_time.setSliderStyle(juce::Slider::SliderStyle::LinearHorizontal);
		release_time.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		release_time.setTextBoxIsEditable(true);
		release_time.mc = this;

		// LFO GROUP
		addAndMakeVisible(lfo1_group);
		lfo1_group.setText("LFO1");
		lfo1_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(lfo1_saw);
		vComponents.push_back(std::make_pair(&lfo1_saw, 1));
		addAndMakeVisible(lfo1_tri);
		vComponents.push_back(std::make_pair(&lfo1_tri, 1));
		addAndMakeVisible(lfo1_squ);
		vComponents.push_back(std::make_pair(&lfo1_squ, 1));
		addAndMakeVisible(lfo1_sin);
		vComponents.push_back(std::make_pair(&lfo1_sin, 1));
		lfo1_saw.setComponentID("0x11");
		lfo1_saw.setName("0");
		audioProcessor->midi_comp.set("0x11a", std::make_pair(&lfo1_saw, 1));
		lfo1_saw.setRadioGroupId(300);
		lfo1_saw.setToggleState(true, juce::dontSendNotification);
		lfo1_saw.onClick = [this] { WaveTypeChanged(&lfo1_saw, "0"); };
		lfo1_tri.setComponentID("0x11");
		lfo1_tri.setName("1");
		audioProcessor->midi_comp.set("0x11b", std::make_pair(&lfo1_tri, 1));
		lfo1_tri.setRadioGroupId(300);
		lfo1_tri.onClick = [this] { WaveTypeChanged(&lfo1_tri, "1"); };
		lfo1_squ.setComponentID("0x11");
		lfo1_squ.setName("2");
		audioProcessor->midi_comp.set("0x11c", std::make_pair(&lfo1_squ, 1));
		lfo1_squ.setRadioGroupId(300);
		lfo1_squ.onClick = [this] { WaveTypeChanged(&lfo1_squ, "2"); };
		lfo1_sin.setComponentID("0x11");
		lfo1_sin.setName("3");
		audioProcessor->midi_comp.set("0x11d", std::make_pair(&lfo1_sin, 1));
		lfo1_sin.setRadioGroupId(300);
		lfo1_sin.onClick = [this] { WaveTypeChanged(&lfo1_sin, "3"); };

		if (audioProcessor->pvalues["0x11"] == 3) {
			lfo1_sin.setToggleState(true, juce::dontSendNotification);
			lfo1_value = "3";
		}
		else if (audioProcessor->pvalues["0x11"] == 2) {
			lfo1_squ.setToggleState(true, juce::dontSendNotification);
			lfo1_value = "2";
		}
		else if (audioProcessor->pvalues["0x11"] == 1) {
			lfo1_tri.setToggleState(true, juce::dontSendNotification);
			lfo1_value = "1";
		}
		else {
			lfo1_saw.setToggleState(true, juce::dontSendNotification);
			lfo1_value = "0";
		}

		addAndMakeVisible(lfo1_speed);
		vComponents.push_back(std::make_pair(&lfo1_speed, 2));
		audioProcessor->midi_comp.set("0x12", std::make_pair(&lfo1_speed, 2));
		lfo1_speed.setComponentID("0x12");
		lfo1_speed_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x12", lfo1_speed));
		lfo1_speed.setValue(audioProcessor->pvalues["0x12"], juce::sendNotification);
		lfo1_speed.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		lfo1_speed.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		lfo1_speed.setTextBoxIsEditable(true);
		lfo1_speed.mc = this;

		addAndMakeVisible(lfo1_speed_label);
		lfo1_speed_label.setText("SPEED", juce::dontSendNotification);
		lfo1_speed_label.attachToComponent(&lfo1_speed, true);
		lfo1_speed_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		lfo1_speed_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(lfo1_button_left);
		vComponents.push_back(std::make_pair(&lfo1_button_left, 3));
		lfo1_button_left.setComponentID("0x22");
		lfo1_button_left.setName("1");
		audioProcessor->midi_comp.set("0x22a", std::make_pair(&lfo1_button_left, 1));
		lfo1_button_left.setButtonText("1");
		lfo1_button_left.setRadioGroupId(600);
		lfo1_button_left.onClick = [this] { lfoModeChanged(&lfo1_button_left); };

		addAndMakeVisible(lfo1_button_right);
		vComponents.push_back(std::make_pair(&lfo1_button_right, 3));
		lfo1_button_right.setComponentID("0x22");
		lfo1_button_right.setName("2");
		audioProcessor->midi_comp.set("0x22b", std::make_pair(&lfo1_button_right, 1));
		lfo1_button_right.setButtonText("3");
		lfo1_button_right.setRadioGroupId(600);
		lfo1_button_right.onClick = [this] { lfoModeChanged(&lfo1_button_right); };

		if (audioProcessor->pvalues["0x22"] == 0 || audioProcessor->pvalues["0x22"] == 1) {
			lfo1_button_left.setButtonText(std::to_string(audioProcessor->pvalues["0x22"] + 1));
			lfo1_button_left.setToggleState(true, juce::dontSendNotification);
		}
		else if (audioProcessor->pvalues["0x22"] == 2 || audioProcessor->pvalues["0x22"] == 3) {
			lfo1_button_right.setButtonText(std::to_string(audioProcessor->pvalues["0x22"] + 1));
			lfo1_button_right.setToggleState(true, juce::dontSendNotification);
		}

		// LFO2 GROUP
		addAndMakeVisible(lfo2_group);
		lfo2_group.setText("LFO2");
		lfo2_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(lfo2_saw);
		vComponents.push_back(std::make_pair(&lfo2_saw, 1));
		addAndMakeVisible(lfo2_tri);
		vComponents.push_back(std::make_pair(&lfo2_tri, 1));
		addAndMakeVisible(lfo2_squ);
		vComponents.push_back(std::make_pair(&lfo2_squ, 1));
		addAndMakeVisible(lfo2_sin);
		vComponents.push_back(std::make_pair(&lfo2_sin, 1));
		lfo2_saw.setComponentID("0x13");
		lfo2_saw.setName("0");
		audioProcessor->midi_comp.set("0x13a", std::make_pair(&lfo2_saw, 1));
		lfo2_saw.setRadioGroupId(400);
		lfo2_saw.setToggleState(true, juce::dontSendNotification);
		lfo2_saw.onClick = [this] { WaveTypeChanged(&lfo2_saw, "0"); };
		lfo2_tri.setComponentID("0x13");
		lfo2_tri.setName("1");
		audioProcessor->midi_comp.set("0x13b", std::make_pair(&lfo2_tri, 1));
		lfo2_tri.setRadioGroupId(400);
		lfo2_tri.onClick = [this] { WaveTypeChanged(&lfo2_tri, "1"); };
		lfo2_squ.setComponentID("0x13");
		lfo2_squ.setName("2");
		audioProcessor->midi_comp.set("0x13c", std::make_pair(&lfo2_squ, 1));
		lfo2_squ.setRadioGroupId(400);
		lfo2_squ.onClick = [this] { WaveTypeChanged(&lfo2_squ, "2"); };
		lfo2_sin.setComponentID("0x13");
		lfo2_sin.setName("3");
		audioProcessor->midi_comp.set("0x13d", std::make_pair(&lfo2_sin, 1));
		lfo2_sin.setRadioGroupId(400);
		lfo2_sin.onClick = [this] { WaveTypeChanged(&lfo2_sin, "3"); };

		if (audioProcessor->pvalues["0x13"] == 3) {
			lfo2_sin.setToggleState(true, juce::dontSendNotification);
			lfo2_value = "3";
		}
		else if (audioProcessor->pvalues["0x13"] == 2) {
			lfo2_squ.setToggleState(true, juce::dontSendNotification);
			lfo2_value = "2";
		}
		else if (audioProcessor->pvalues["0x13"] == 1) {
			lfo2_tri.setToggleState(true, juce::dontSendNotification);
			lfo2_value = "1";
		}
		else {
			lfo2_saw.setToggleState(true, juce::dontSendNotification);
			lfo2_value = "0";
		}

		addAndMakeVisible(lfo2_speed);
		vComponents.push_back(std::make_pair(&lfo2_speed, 2));
		audioProcessor->midi_comp.set("0x14", std::make_pair(&lfo2_speed, 2));
		lfo2_speed.setComponentID("0x14");
		lfo2_speed_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x14", lfo2_speed));
		lfo2_speed.setValue(audioProcessor->pvalues["0x14"], juce::sendNotification);
		lfo2_speed.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		lfo2_speed.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		lfo2_speed.setTextBoxIsEditable(true);
		lfo2_speed.mc = this;

		addAndMakeVisible(lfo2_speed_label);
		lfo2_speed_label.setText("SPEED", juce::dontSendNotification);
		lfo2_speed_label.attachToComponent(&lfo2_speed, true);
		lfo2_speed_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		lfo2_speed_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(lfo2_button_left);
		vComponents.push_back(std::make_pair(&lfo2_button_left, 3));
		lfo2_button_left.setComponentID("0x23");
		lfo2_button_left.setName("1");
		audioProcessor->midi_comp.set("0x23a", std::make_pair(&lfo2_button_left, 1));
		lfo2_button_left.setButtonText("1");
		lfo2_button_left.setRadioGroupId(700);
		lfo2_button_left.onClick = [this] { lfoModeChanged(&lfo2_button_left); };

		addAndMakeVisible(lfo2_button_right);
		vComponents.push_back(std::make_pair(&lfo2_button_right, 3));
		lfo2_button_right.setComponentID("0x23");
		lfo2_button_right.setName("2");
		audioProcessor->midi_comp.set("0x23b", std::make_pair(&lfo2_button_right, 1));
		lfo2_button_right.setButtonText("3");
		lfo2_button_right.setRadioGroupId(700);
		lfo2_button_right.onClick = [this] { lfoModeChanged(&lfo2_button_right); };

		if (audioProcessor->pvalues["0x23"] == 0 || audioProcessor->pvalues["0x23"] == 1) {
			lfo2_button_left.setButtonText(std::to_string(audioProcessor->pvalues["0x23"] + 1));
			lfo2_button_left.setToggleState(true, juce::dontSendNotification);
		}
		else if (audioProcessor->pvalues["0x23"] == 2 || audioProcessor->pvalues["0x23"] == 3) {
			lfo2_button_right.setButtonText(std::to_string(audioProcessor->pvalues["0x23"] + 1));
			lfo2_button_right.setToggleState(true, juce::dontSendNotification);
		}

		// LFO3 GROUP
		addAndMakeVisible(lfo3_group);
		lfo3_group.setText("LFO3");
		lfo3_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(lfo3_saw);
		vComponents.push_back(std::make_pair(&lfo3_saw, 1));
		addAndMakeVisible(lfo3_tri);
		vComponents.push_back(std::make_pair(&lfo3_tri, 1));
		addAndMakeVisible(lfo3_squ);
		vComponents.push_back(std::make_pair(&lfo3_squ, 1));
		addAndMakeVisible(lfo3_sin);
		vComponents.push_back(std::make_pair(&lfo3_sin, 1));
		lfo3_saw.setComponentID("0x36");
		lfo3_saw.setName("0");
		audioProcessor->midi_comp.set("0x36a", std::make_pair(&lfo3_saw, 1));
		lfo3_saw.setRadioGroupId(500);
		lfo3_saw.setToggleState(true, juce::dontSendNotification);
		lfo3_saw.onClick = [this] { WaveTypeChanged(&lfo3_saw, "0"); };
		lfo3_tri.setComponentID("0x36");
		lfo3_tri.setName("1");
		audioProcessor->midi_comp.set("0x36b", std::make_pair(&lfo3_tri, 1));
		lfo3_tri.setRadioGroupId(500);
		lfo3_tri.onClick = [this] { WaveTypeChanged(&lfo3_tri, "1"); };
		lfo3_squ.setComponentID("0x36");
		lfo3_squ.setName("2");
		audioProcessor->midi_comp.set("0x36c", std::make_pair(&lfo3_squ, 1));
		lfo3_squ.setRadioGroupId(500);
		lfo3_squ.onClick = [this] { WaveTypeChanged(&lfo3_squ, "2"); };
		lfo3_sin.setComponentID("0x36");
		lfo3_sin.setName("3");
		audioProcessor->midi_comp.set("0x36d", std::make_pair(&lfo3_sin, 1));
		lfo3_sin.setRadioGroupId(500);
		lfo3_sin.onClick = [this] { WaveTypeChanged(&lfo3_sin, "3"); };

		if (audioProcessor->pvalues["0x36"] == 3) {
			lfo3_sin.setToggleState(true, juce::dontSendNotification);
			lfo3_value = "3";
		}
		else if (audioProcessor->pvalues["0x36"] == 2) {
			lfo3_squ.setToggleState(true, juce::dontSendNotification);
			lfo3_value = "2";
		}
		else if (audioProcessor->pvalues["0x36"] == 1) {
			lfo3_tri.setToggleState(true, juce::dontSendNotification);
			lfo3_value = "1";
		}
		else {
			lfo3_saw.setToggleState(true, juce::dontSendNotification);
			lfo3_value = "0";
		}

		addAndMakeVisible(lfo3_speed);
		vComponents.push_back(std::make_pair(&lfo3_speed, 2));
		audioProcessor->midi_comp.set("0x37", std::make_pair(&lfo3_speed, 2));
		lfo3_speed.setComponentID("0x37");
		lfo3_speed_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x37", lfo3_speed));
		lfo3_speed.setValue(audioProcessor->pvalues["0x37"], juce::sendNotification);
		lfo3_speed.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		lfo3_speed.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		lfo3_speed.setTextBoxIsEditable(true);
		lfo3_speed.mc = this;

		addAndMakeVisible(lfo3_speed_label);
		lfo3_speed_label.setText("SPEED", juce::dontSendNotification);
		lfo3_speed_label.attachToComponent(&lfo3_speed, true);
		lfo3_speed_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		lfo3_speed_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(lfo3_button_left);
		vComponents.push_back(std::make_pair(&lfo3_button_left, 3));
		lfo3_button_left.setComponentID("0x38");
		lfo3_button_left.setName("1");
		audioProcessor->midi_comp.set("0x38a", std::make_pair(&lfo3_button_left, 1));
		lfo3_button_left.setButtonText("1");
		lfo3_button_left.setRadioGroupId(800);
		lfo3_button_left.onClick = [this] { lfoModeChanged(&lfo3_button_left); };

		addAndMakeVisible(lfo3_button_right);
		vComponents.push_back(std::make_pair(&lfo3_button_right, 3));
		lfo3_button_right.setComponentID("0x38");
		lfo3_button_right.setName("2");
		audioProcessor->midi_comp.set("0x38b", std::make_pair(&lfo3_button_right, 1));
		lfo3_button_right.setButtonText("3");
		lfo3_button_right.setRadioGroupId(800);
		lfo3_button_right.onClick = [this] { lfoModeChanged(&lfo3_button_right); };

		if (audioProcessor->pvalues["0x38"] == 0 || audioProcessor->pvalues["0x38"] == 1) {
			lfo3_button_left.setButtonText(std::to_string(audioProcessor->pvalues["0x38"] + 1));
			lfo3_button_left.setToggleState(true, juce::dontSendNotification);
		}
		else if (audioProcessor->pvalues["0x38"] == 2 || audioProcessor->pvalues["0x38"] == 3) {
			lfo3_button_right.setButtonText(std::to_string(audioProcessor->pvalues["0x38"] + 1));
			lfo3_button_right.setToggleState(true, juce::dontSendNotification);
		}

		addAndMakeVisible(lfo3_destination);
		vComponents.push_back(std::make_pair(&lfo3_destination, 4));
		audioProcessor->midi_comp.set("0x39", std::make_pair(&lfo3_destination, 4));
		lfo3_destination.setComponentID("0x39");
		lfo3_destination_attach.reset(new juce::AudioProcessorValueTreeState::ComboBoxAttachment(parameters, "0x39", lfo3_destination));
		lfo3_destination.addItem("FREQUENCY", 1);
		lfo3_destination.addItem("RESONANCE", 2);

		if (audioProcessor->pvalues["0x39"] == 0 || audioProcessor->pvalues["0x39"] == 1)
			lfo3_destination.setSelectedItemIndex(0, juce::sendNotification);
		else
			lfo3_destination.setSelectedItemIndex(1, juce::sendNotification);

		// PORTAMENTO GROUP
		addAndMakeVisible(portamento_group);
		portamento_group.setText("PORTAMENTO");
		portamento_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(portamento);
		vComponents.push_back(std::make_pair(&portamento, 2));
		audioProcessor->midi_comp.set("0x21", std::make_pair(&portamento, 2));
		portamento.setComponentID("0x21");
		portamento_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x21", portamento));
		portamento.setValue(audioProcessor->pvalues["0x21"], juce::sendNotification);
		portamento.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		portamento.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		portamento.setTextBoxIsEditable(true);
		portamento.mc = this;

		addAndMakeVisible(portamento_label);
		portamento_label.setText("PORTAMENTO", juce::dontSendNotification);
		portamento_label.attachToComponent(&portamento, true);
		portamento_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		portamento_label.setJustificationType(juce::Justification::centred);

		// MASTER GROUP
		addAndMakeVisible(master_group);
		master_group.setText("MASTER");
		master_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(master);
		vComponents.push_back(std::make_pair(&master, 2));
		audioProcessor->midi_comp.set("0x05", std::make_pair(&master, 2));
		master.setComponentID("0x05");
		master_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x05", master));
		master.setValue(audioProcessor->pvalues["0x05"], juce::sendNotification);
		master.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		master.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		master.setTextBoxIsEditable(true);
		master.mc = this;

		addAndMakeVisible(master_label);
		master_label.setText("MASTER", juce::dontSendNotification);
		master_label.attachToComponent(&master, true);
		master_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		master_label.setJustificationType(juce::Justification::centred);

		// FILTER GROUP
		addAndMakeVisible(filter_group);
		filter_group.setText("FILTER");
		filter_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(filter_freq);
		vComponents.push_back(std::make_pair(&filter_freq, 2));
		audioProcessor->midi_comp.set("0x0D", std::make_pair(&filter_freq, 2));
		filter_freq.setComponentID("0x0D");
		filter_freq_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x0D", filter_freq));
		filter_freq.setValue(audioProcessor->pvalues["0x0D"], juce::sendNotification);
		filter_freq.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		filter_freq.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		filter_freq.setTextBoxIsEditable(true);
		filter_freq.mc = this;

		addAndMakeVisible(filter_freq_label);
		filter_freq_label.setText("FREQUENCY", juce::dontSendNotification);
		filter_freq_label.attachToComponent(&filter_freq, false);
		filter_freq_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		filter_freq_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(filter_q);
		vComponents.push_back(std::make_pair(&filter_q, 2));
		audioProcessor->midi_comp.set("0x0E", std::make_pair(&filter_q, 2));
		filter_q.setComponentID("0x0E");
		filter_q_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x0E", filter_q));
		filter_q.setValue(audioProcessor->pvalues["0x0E"], juce::sendNotification);
		filter_q.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		filter_q.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		filter_q.setTextBoxIsEditable(true);
		filter_q.mc = this;

		addAndMakeVisible(filter_q_label);
		filter_q_label.setText("RESONANCE", juce::dontSendNotification);
		filter_q_label.attachToComponent(&filter_q, true);
		filter_q_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		filter_q_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(filter_lfo);
		vComponents.push_back(std::make_pair(&filter_lfo, 2));
		audioProcessor->midi_comp.set("0x0F", std::make_pair(&filter_lfo, 2));
		filter_lfo.setComponentID("0x0F");
		filter_lfo_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x0F", filter_lfo));
		filter_lfo.setValue(audioProcessor->pvalues["0x0F"], juce::sendNotification);
		filter_lfo.setSliderStyle(juce::Slider::SliderStyle::LinearHorizontal);
		filter_lfo.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		filter_lfo.setTextBoxIsEditable(true);
		filter_lfo.mc = this;

		addAndMakeVisible(filter_lfo_label);
		filter_lfo_label.setText("LFO3", juce::dontSendNotification);
		filter_lfo_label.attachToComponent(&filter_lfo, true);
		filter_lfo_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		filter_lfo_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(filter_type);
		vComponents.push_back(std::make_pair(&filter_type, 4));
		audioProcessor->midi_comp.set("0x10", std::make_pair(&filter_type, 4));
		filter_type.setComponentID("0x10");
		filter_type_attach.reset(new juce::AudioProcessorValueTreeState::ComboBoxAttachment(parameters, "0x10", filter_type));
		filter_type.addItem("OFF", 1);
		filter_type.addItem("LOW PASS", 2);
		filter_type.addItem("HIGH PASS", 3);
		filter_type.addItem("BAND PASS", 4);
		filter_type.addItem("NOTCH", 5);
		filter_type.setSelectedItemIndex(audioProcessor->pvalues["0x10"], juce::sendNotification);

		// NOISE GROUP
		addAndMakeVisible(noise_group);
		noise_group.setText("SYNTH");
		noise_group.setTextLabelPosition(juce::Justification::centred);

		addAndMakeVisible(noise_volume);
		vComponents.push_back(std::make_pair(&noise_volume, 2));
		audioProcessor->midi_comp.set("0x15", std::make_pair(&noise_volume, 2));
		noise_volume.setComponentID("0x15");
		noise_volume_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x15", noise_volume));
		noise_volume.setValue(audioProcessor->pvalues["0x15"], juce::sendNotification);
		noise_volume.setSliderStyle(juce::Slider::SliderStyle::RotaryHorizontalVerticalDrag);
		noise_volume.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		noise_volume.setTextBoxIsEditable(true);
		noise_volume.mc = this;

		addAndMakeVisible(noise_volume_label);
		noise_volume_label.setText("NOISE", juce::dontSendNotification);
		noise_volume_label.attachToComponent(&noise_volume, true);
		noise_volume_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		noise_volume_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(pmod_in);
		vComponents.push_back(std::make_pair(&pmod_in, 2));
		audioProcessor->midi_comp.set("0x16", std::make_pair(&pmod_in, 2));
		pmod_in.setComponentID("0x16");
		pmod_in_attach.reset(new juce::AudioProcessorValueTreeState::SliderAttachment(parameters, "0x16", pmod_in));
		pmod_in.setValue(audioProcessor->pvalues["0x16"], juce::sendNotification);
		pmod_in.setSliderStyle(juce::Slider::SliderStyle::LinearHorizontal);
		pmod_in.setTextBoxStyle(juce::Slider::TextBoxBelow, true, 80, 25);
		pmod_in.setTextBoxIsEditable(true);
		pmod_in.mc = this;

		addAndMakeVisible(pmod_in_label);
		pmod_in_label.setText("PMOD", juce::dontSendNotification);
		pmod_in_label.attachToComponent(&pmod_in, true);
		pmod_in_label.setColour(juce::Label::outlineColourId, juce::Colour(142, 152, 155));
		pmod_in_label.setJustificationType(juce::Justification::centred);

		addAndMakeVisible(app_name_label);
#if STANDALONE
		app_name_label.setText("FPGA SYNTH\nCONTROLLER\nStandalone", juce::dontSendNotification);
#else
		app_name_label.setText("FPGA SYNTH\nCONTROLLER\nVST3 1.0", juce::dontSendNotification);
#endif
		app_name_label.setColour(juce::Label::textColourId, juce::Colours::white);
		app_name_label.setJustificationType(juce::Justification::centred);
		app_name_label.setFont(juce::Font(20.0f, juce::Font::bold));

		addAndMakeVisible(options_button);
		options_button.setButtonText("OPTIONS");
		options_button.onClick = [this] { showWindow(); };

		addAndMakeVisible(presets_button);
		presets_button.setButtonText("PRESETS");
		presets_button.onClick = [this] { showPresets(); };

#if STANDALONE
		audioProcessor->FPGA_Connection();
#endif
	}

	~MainComponent() override
	{
		if (basicWindow != nullptr)
			basicWindow->closeButtonPressed();

		//if (audioProcessor->hComm != nullptr)
			//CloseHandle(audioProcessor->hComm);
	}

	void paint(juce::Graphics&) override
	{
	}

	void resized() override
	{
		osc1_group.setBounds(3, 5, 836, 145);
		osc1_saw.setBounds(10, 17, 105, 35);
		osc1_tri.setBounds(10, 47, 105, 35);
		osc1_squ.setBounds(10, 77, 105, 35);
		osc1_sin.setBounds(10, 107, 105, 35);
		osc1_semitone.setBounds(152, 0, 90, 143);
		osc1_semitone_label.setBounds(147, 95, 100, 20);
		osc1_detune.setBounds(288, 0, 90, 143);
		osc1_detune_label.setBounds(283, 95, 100, 20);
		osc1_lfo.setBounds(424, 0, 90, 143);
		osc1_lfo_label.setBounds(419, 95, 100, 20);
		osc1_pulse.setBounds(560, 0, 90, 143);
		osc1_pulse_label.setBounds(555, 95, 100, 20);
		osc1_volume.setBounds(696, 0, 90, 143);
		osc1_volume_label.setBounds(691, 95, 100, 20);

		osc2_group.setBounds(3, 150, 836, 145);
		osc2_saw.setBounds(10, 162, 105, 35);
		osc2_tri.setBounds(10, 192, 105, 35);
		osc2_squ.setBounds(10, 222, 105, 35);
		osc2_sin.setBounds(10, 252, 105, 35);
		osc2_semitone.setBounds(152, 145, 90, 143);
		osc2_semitone_label.setBounds(147, 240, 100, 20);
		osc2_detune.setBounds(288, 145, 90, 143);
		osc2_detune_label.setBounds(283, 240, 100, 20);
		osc2_lfo.setBounds(424, 145, 90, 143);
		osc2_lfo_label.setBounds(419, 240, 100, 20);
		osc2_pulse.setBounds(560, 145, 90, 143);
		osc2_pulse_label.setBounds(555, 240, 100, 20);
		osc2_volume.setBounds(696, 145, 90, 143);
		osc2_volume_label.setBounds(691, 240, 100, 20);

		amp_env_group.setBounds(3, 295, 435, 305);
		attack.setBounds(25, 310, 75, 212);
		attack_label.setBounds(13, 530, 100, 20);
		attack_time.setBounds(4, 557, 113, 35);
		decay.setBounds(130, 310, 75, 212);
		decay_label.setBounds(118, 530, 100, 20);
		decay_time.setBounds(109, 557, 113, 35);
		sustain.setBounds(235, 310, 75, 212);
		sustain_label.setBounds(223, 530, 100, 20);
		sustain_time.setBounds(230, 572, 80, 20);
		release.setBounds(340, 310, 75, 212);
		release_label.setBounds(328, 530, 100, 20);
		release_time.setBounds(319, 557, 113, 35);

		lfo1_group.setBounds(440, 295, 250, 150);
		lfo1_saw.setBounds(450, 307, 105, 35);
		lfo1_tri.setBounds(450, 337, 105, 35);
		lfo1_squ.setBounds(450, 367, 105, 35);
		lfo1_sin.setBounds(450, 397, 105, 35);
		lfo1_speed.setBounds(570, 290, 90, 144);
		lfo1_speed_label.setBounds(563, 384, 100, 20);
		lfo1_button_left.setBounds(547, 409, 35, 25);
		lfo1_button_right.setBounds(649, 409, 35, 25);

		lfo2_group.setBounds(440, 450, 250, 150);
		lfo2_saw.setBounds(450, 462, 105, 35);
		lfo2_tri.setBounds(450, 492, 105, 35);
		lfo2_squ.setBounds(450, 522, 105, 35);
		lfo2_sin.setBounds(450, 552, 105, 35);
		lfo2_speed.setBounds(570, 445, 90, 144);
		lfo2_speed_label.setBounds(563, 539, 100, 20);
		lfo2_button_left.setBounds(547, 564, 35, 25);
		lfo2_button_right.setBounds(649, 564, 35, 25);

		lfo3_group.setBounds(699, 295, 140, 305);
		lfo3_saw.setBounds(706, 307, 105, 35);
		lfo3_tri.setBounds(706, 337, 105, 35);
		lfo3_squ.setBounds(706, 367, 105, 35);
		lfo3_sin.setBounds(706, 397, 105, 35);
		lfo3_speed.setBounds(724, 443, 90, 146);
		lfo3_speed_label.setBounds(719, 536, 100, 23);
		lfo3_button_left.setBounds(705, 564, 35, 25);
		lfo3_button_right.setBounds(798, 564, 35, 25);
		lfo3_destination.setBounds(709, 433, 120, 30);

		portamento_group.setBounds(845, 445, 140, 155);
		portamento.setBounds(870, 440, 90, 149);
		portamento_label.setBounds(865, 538, 100, 20);

		master_group.setBounds(991, 445, 140, 155);
		master.setBounds(1016, 440, 90, 149);
		master_label.setBounds(1011, 538, 100, 20);

		filter_group.setBounds(845, 5, 140, 435);
		filter_freq.setBounds(870, 0, 90, 143);
		filter_freq_label.setBounds(865, 95, 100, 20);
		filter_q.setBounds(870, 145, 90, 143);
		filter_q_label.setBounds(865, 240, 100, 20);
		filter_type.setBounds(855, 303, 120, 30);
		filter_lfo.setBounds(859, 320, 113, 113);
		filter_lfo_label.setBounds(865, 384, 100, 20);

		noise_group.setBounds(991, 150, 140, 290);
		noise_volume.setBounds(1016, 145, 90, 143);
		noise_volume_label.setBounds(1011, 240, 100, 20);
		pmod_in.setBounds(1005, 320, 113, 113);
		pmod_in_label.setBounds(1011, 384, 100, 20);

		app_name_label.setBounds(931, 3, 250, 80);
		options_button.setBounds(1004, 103, 110, 40);
		presets_button.setBounds(1004, 303, 110, 40);
	}

	class mySlider : public juce::Slider
	{
	public:
		MainComponent* mc;

		void mouseDown(const juce::MouseEvent& e)
		{
			Slider::mouseDown(e);

			if (e.mods.isRightButtonDown()) {
				if (isEnabled()) {
					if (e.mods.isPopupMenu())
					{
						juce::PopupMenu m;
						m.addItem(1, TRANS("Learn"), true, false);
						m.showMenuAsync(juce::PopupMenu::Options(), juce::ModalCallbackFunction::forComponent(sliderMenuCallback, this, mc));
					}
				}
			}
		}

		static void sliderMenuCallback(int result, mySlider* slider, MainComponent* mc)
		{
			if (slider != nullptr)
			{
				switch (result)
				{
				case 1:
					mc->audioProcessor->learning = true;
					mc->audioProcessor->sliderId = slider->getComponentID();
					//m->update_midicc(0, 5);
					//m->write_json();
					break;
				default:  break;
				}
			}
		}

	private:
	};

	std::unique_ptr<juce::AlertWindow> asyncAlertWindow;
	struct AsyncAlertBoxResultChosen
	{
		void operator() (int result) const noexcept
		{
			auto& aw = *demo.asyncAlertWindow;
			aw.exitModalState(result);
			aw.setVisible(false);
			if (aw.getCustomComponent(0) != nullptr)
				delete aw.getCustomComponent(0);

			if (result == 0)
			{
				return;
			}
			else if (result == 1) {
				if (aw.getTextEditorContents("com_port").isNotEmpty()) {
					if (aw.getTextEditorContents("com_port").startsWith("COM")) {
						demo.audioProcessor->com_port_value = aw.getTextEditorContents("com_port");
						demo.audioProcessor->FPGA_Connection();

						if (demo.audioProcessor->connected) {
							juce::String path(demo.audioProcessor->getCurrentExePath() + "\\settings.ini");
							juce::File(path).replaceWithText(demo.audioProcessor->com_port_value);
						}
					}
				}
			}
			else if (result == 2) {
				juce::MessageBoxIconType icon = juce::MessageBoxIconType::InfoIcon;
				juce::AlertWindow::showMessageBoxAsync(icon, "FPGA Synth Controller",
					"This is the FPGA Synth Controller project.",
					"OK");
			}
		}

		MainComponent& demo;
	};

	class Tabla : public Component,
		public juce::TableListBoxModel
	{
	public:
		Tabla(MainComponent* mainComponent)
		{
			setSize(635, 400);

			mc = mainComponent;

			// Load some data from an embedded XML file..
			loadData();

			// Create our table component and add it to this component..
			addAndMakeVisible(table);
			table.setModel(this);

			// give it a border
			table.setColour(juce::ListBox::outlineColourId, juce::Colours::grey);
			table.setOutlineThickness(8);

			// Add some columns to the table header, based on the column list in our database..
			for (auto* columnXml : columnList->getChildIterator())
			{
				table.getHeader().addColumn(columnXml->getStringAttribute("name"),
					columnXml->getIntAttribute("columnId"),
					columnXml->getIntAttribute("width"),
					50, 200,
					juce::TableHeaderComponent::defaultFlags);
			}

			// we could now change some initial settings..
			table.getHeader().setSortColumnId(1, true); // sort forwards by the ID column
			//table.getHeader().setColumnVisible(7, false); // hide the "length" column until the user shows it

			// un-comment this line to have a go of stretch-to-fit mode
			//table.getHeader().setStretchToFitActive (true);

			//table.setMultipleSelectionEnabled(true);

			addAndMakeVisible(new_button);
			new_button.setButtonText("NEW");
			if (getNumRows() > 998)
				new_button.setEnabled(false);
			new_button.onClick = [this] { newPreset(); };

			addAndMakeVisible(save_button);
			save_button.setButtonText("SAVE");
			save_button.setEnabled(false);
			save_button.onClick = [this] { savePreset(); };

			addAndMakeVisible(close_button);
			close_button.setButtonText("CLOSE");
			close_button.onClick = [this] { closeWindow(); };
		}

		~Tabla()
		{
			if (modified) {
				juce::XmlElement xml("DEMO_TABLE_DATA");
				juce::XmlElement* x2 = new juce::XmlElement(*columnList);
				xml.addChildElement(x2);
				x2 = new juce::XmlElement(*dataList);
				xml.addChildElement(x2);

				juce::File path(juce::String(juce::File::getSpecialLocation(juce::File::currentExecutableFile).getCurrentWorkingDirectory().getFullPathName() + "\\presets.xml"));
				juce::File file(path);
				xml.writeTo(file, juce::XmlElement::TextFormat::TextFormat());
			}
			modified = false;
			selected_index = -1;
			save_button.setEnabled(false);

			table.setModel(nullptr);
		}

		void newPreset()
		{
			newPresetWindow = std::make_unique<juce::AlertWindow>("New Preset Data", "", juce::MessageBoxIconType::QuestionIcon);

			std::string str = std::to_string(getNumRows() + 1);
			std::string s = std::string(3 - str.size(), '0').append(str);
			newPresetWindow->addTextEditor("ID", s, "ID:");
			newPresetWindow->addTextEditor("Preset", "Preset name", "Preset:");
			newPresetWindow->addTextEditor("Category", "Unknown", "Category:");
			newPresetWindow->addTextEditor("Autor", "Your name", "Autor:");

			juce::Label* cp = (juce::Label*)newPresetWindow->getChildComponent(1);
			cp->setEnabled(false);

			newPresetWindow->addComboBox("Rating", { }, "Rating:");
			juce::ComboBox* cb = (juce::ComboBox*)newPresetWindow->getChildComponent(5);
			cb->addItem("5 stars", 1);
			cb->addItem("4 stars", 2);
			cb->addItem("3 stars", 3);
			cb->addItem("2 stars", 4);
			cb->addItem("1 stars", 5);
			cb->setSelectedId(1, juce::dontSendNotification);

			newPresetWindow->addButton("ACCEPT", 1, juce::KeyPress(juce::KeyPress::returnKey, 0, 0));
			newPresetWindow->addButton("CANCEL", 0, juce::KeyPress(juce::KeyPress::escapeKey, 0, 0));

			newPresetWindow->enterModalState(true, juce::ModalCallbackFunction::create(newPresetResultChosen{ *this }));
		}

		void savePreset()
		{
			savePresetWindow = std::make_unique<juce::AlertWindow>("Save Preset Data", "", juce::MessageBoxIconType::QuestionIcon);

			savePresetWindow->addTextEditor("ID", dataList->getChildElement(selected_index)->getStringAttribute("ID"), "ID:");
			savePresetWindow->addTextEditor("Preset", dataList->getChildElement(selected_index)->getStringAttribute("Preset"), "Preset:");
			savePresetWindow->addTextEditor("Category", dataList->getChildElement(selected_index)->getStringAttribute("Category"), "Category:");
			savePresetWindow->addTextEditor("Autor", dataList->getChildElement(selected_index)->getStringAttribute("Autor"), "Autor:");

			Component* cp = savePresetWindow->getChildComponent(1);
			cp->setEnabled(false);

			savePresetWindow->addComboBox("Rating", { }, "Rating:");
			juce::ComboBox* cb = (juce::ComboBox*)savePresetWindow->getChildComponent(5);
			cb->addItem("5 stars", 1);
			cb->addItem("4 stars", 2);
			cb->addItem("3 stars", 3);
			cb->addItem("2 stars", 4);
			cb->addItem("1 stars", 5);
			cb->setSelectedId(dataList->getChildElement(selected_index)->getStringAttribute("Rating").getIntValue(), juce::dontSendNotification);

			savePresetWindow->addButton("ACCEPT", 1, juce::KeyPress(juce::KeyPress::returnKey, 0, 0));
			savePresetWindow->addButton("CANCEL", 0, juce::KeyPress(juce::KeyPress::escapeKey, 0, 0));

			savePresetWindow->enterModalState(true, juce::ModalCallbackFunction::create(savePresetResultChosen{ *this }));
		}

		void closeWindow()
		{
			if (mc->basicWindow != nullptr)
				mc->basicWindow->closeButtonPressed();
		}

		// This is overloaded from TableListBoxModel, and must return the total number of rows in our table
		int getNumRows() override
		{
			return numRows;
		}

		// This is overloaded from TableListBoxModel, and should fill in the background of the whole row
		void paintRowBackground(juce::Graphics& g, int rowNumber, int, int, bool rowIsSelected) override
		{
			auto alternateColour = getLookAndFeel().findColour(juce::ListBox::backgroundColourId)
				.interpolatedWith(getLookAndFeel().findColour(juce::ListBox::textColourId), 0.03f);
			if (rowIsSelected)
				g.fillAll(juce::Colours::lightblue);
			else if (rowNumber % 2)
				g.fillAll(alternateColour);
		}

		// This is overloaded from TableListBoxModel, and must paint any cells that aren't using custom
		// components.
		void paintCell(juce::Graphics& g, int rowNumber, int columnId,
			int width, int height, bool) override
		{
			g.setColour(getLookAndFeel().findColour(juce::ListBox::textColourId));
			g.setFont(font);

			if (auto* rowElement = dataList->getChildElement(rowNumber))
			{
				auto text = rowElement->getStringAttribute(getAttributeNameForColumnId(columnId));

				g.drawText(text, 2, 0, width - 4, height, juce::Justification::centredLeft, true);
			}

			g.setColour(getLookAndFeel().findColour(juce::ListBox::backgroundColourId));
			g.fillRect(width - 1, 0, 1, height);
		}

		// This is overloaded from TableListBoxModel, and tells us that the user has clicked a table header
		// to change the sort order.
		void sortOrderChanged(int newSortColumnId, bool isForwards) override
		{
			if (newSortColumnId != 0)
			{
				DemoDataSorter sorter(getAttributeNameForColumnId(newSortColumnId), isForwards);
				dataList->sortChildElements(sorter);

				table.updateContent();
			}
		}

		// This is overloaded from TableListBoxModel, and must update any custom components that we're using
		Component* refreshComponentForCell(int rowNumber, int columnId, bool,
			Component* existingComponentToUpdate) override
		{
			if (columnId == 5) // For the ratings column, we return the custom combobox component
			{
				auto* ratingsBox = static_cast<RatingColumnCustomComponent*> (existingComponentToUpdate);

				// If an existing component is being passed-in for updating, we'll re-use it, but
				// if not, we'll have to create one.
				if (ratingsBox == nullptr) {
					ratingsBox = new RatingColumnCustomComponent(*this);

				}

				ratingsBox->setRowAndColumn(rowNumber, columnId);
				return ratingsBox;
			}

			// The other columns are editable text columns, for which we use the custom Label component
			auto* textLabel = static_cast<EditableTextCustomComponent*> (existingComponentToUpdate);

			// same as above...
			if (textLabel == nullptr) {
				textLabel = new EditableTextCustomComponent(*this);
			}

			if (columnId == 1)
				textLabel->setEditable(false, false, false);

			textLabel->setRowAndColumn(rowNumber, columnId);
			return textLabel;
		}

		// This is overloaded from TableListBoxModel, and should choose the best width for the specified
		// column.
		int getColumnAutoSizeWidth(int columnId) override
		{
			if (columnId == 5)
				return 100; // (this is the ratings column, containing a custom combobox component)

			int widest = 32;

			// find the widest bit of text in this column..
			for (int i = getNumRows(); --i >= 0;)
			{
				if (auto* rowElement = dataList->getChildElement(i))
				{
					auto text = rowElement->getStringAttribute(getAttributeNameForColumnId(columnId));

					widest = juce::jmax(widest, font.getStringWidth(text));
				}
			}

			return widest + 8;
		}

		// A couple of quick methods to set and get cell values when the user changes them
		int getRating(const int rowNumber) const
		{
			return dataList->getChildElement(rowNumber)->getIntAttribute("Rating");
		}

		void setRating(const int rowNumber, const int newRating)
		{
			modified = true;
			dataList->getChildElement(rowNumber)->setAttribute("Rating", newRating);
		}

		juce::String getText(const int columnNumber, const int rowNumber) const
		{
			return dataList->getChildElement(rowNumber)->getStringAttribute(getAttributeNameForColumnId(columnNumber));
		}

		void setText(const int columnNumber, const int rowNumber, const juce::String& newText)
		{
			auto columnName = table.getHeader().getColumnName(columnNumber);
			dataList->getChildElement(rowNumber)->setAttribute(columnName, newText);
		}

		//==============================================================================
		void resized() override
		{
			// position our table with a gap around its edge
			//table.setBoundsInset(BorderSize<int>(0));
			table.setBounds(0, 0, 630, 396);
			new_button.setBounds(245, 398, 110, 35);
			save_button.setBounds(375, 398, 110, 35);
			close_button.setBounds(505, 398, 110, 35);
		}

	private:
		MainComponent* mc;
		juce::TableListBox table;     // the table component itself
		juce::Font font{ 14.0f };

		std::unique_ptr<juce::XmlElement> demoData;  // This is the XML document loaded from the embedded file "demo table data.xml"
		juce::XmlElement* columnList = nullptr;     // A pointer to the sub-node of demoData that contains the list of columns
		juce::XmlElement* dataList = nullptr;     // A pointer to the sub-node of demoData that contains the list of data rows
		int numRows;                          // The number of rows of data we've got
		bool modified = false;
		int last_row;
		int selected_index = -1;
		int new_index;

		juce::TextButton new_button;
		juce::TextButton save_button;
		juce::TextButton close_button;

		std::unique_ptr<juce::AlertWindow> newPresetWindow;
		struct newPresetResultChosen
		{
			void operator() (int result) const noexcept
			{
				auto& aw = *tbl.newPresetWindow;
				aw.exitModalState(result);
				aw.setVisible(false);

				if (result == 0)
				{
					return;
				}
				else if (result == 1) {
					juce::String text;
					if (aw.getTextEditorContents("Preset").isNotEmpty() &&
						aw.getTextEditorContents("Category").isNotEmpty() &&
						aw.getTextEditorContents("Autor").isNotEmpty()) {

						juce::XmlElement* first = tbl.dataList->getFirstChildElement();
						//juce::XmlElement*  element = tbl.dataList->findParentElementOf(first);
						juce::XmlElement* elem = new juce::XmlElement("ITEM");
						elem->setAttribute("ID", aw.getTextEditorContents("ID"));
						elem->setAttribute("Preset", aw.getTextEditorContents("Preset"));
						elem->setAttribute("Category", aw.getTextEditorContents("Category"));
						elem->setAttribute("Autor", aw.getTextEditorContents("Autor"));
						auto option = aw.getComboBoxComponent("Rating")->getSelectedItemIndex();
						elem->setAttribute("Rating", option + 1);

						int contador = 1;
						for (int i = 0; i < tbl.mc->vComponents.size(); i++) {
							if (tbl.mc->vComponents[i].second == 1) {
								juce::ToggleButton* tb = (juce::ToggleButton*)tbl.mc->vComponents[i].first;
								if (tb->getToggleState() == 1) {
									switch (tb->getName().getIntValue())
									{
									case 0:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x00");
										break;
									case 1:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x01");
										break;
									case 2:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x02");
										break;
									case 3:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x03");
										break;
									}
								}
							}
							else if (tbl.mc->vComponents[i].second == 2) {
								juce::Slider* sl = (juce::Slider*)tbl.mc->vComponents[i].first;
								elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
								int val = sl->getValue();
								val = val & 0xFF;
								std::string str = juce::String::toHexString(val).toStdString();
								std::string hex = "0x" + std::string(2 - str.size(), '0').append(str);
								elem->setAttribute("v" + juce::String(contador++), hex);
								if (tbl.mc->vComponents[i].first->getComponentID() == "0x0D") { // Filter
									int val = sl->getValue();
									val = (val >> 8) & 0xFF;
									std::string str = juce::String::toHexString(val).toStdString();
									std::string hex = "0x" + std::string(2 - str.size(), '0').append(str);
									elem->setAttribute("v" + juce::String(contador++), hex);
								}
							}
							else if (tbl.mc->vComponents[i].second == 3) {
								juce::ToggleButton* tb = (juce::ToggleButton*)tbl.mc->vComponents[i].first;
								if (tb->getToggleState()) {
									switch (tb->getButtonText().getIntValue())
									{
									case 1:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x00");
										break;
									case 2:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x01");
										break;
									case 3:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x02");
										break;
									case 4:
										elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
										elem->setAttribute("v" + juce::String(contador++), "0x03");
										break;
									}
								}
							}
							else if (tbl.mc->vComponents[i].second == 4) {
								juce::ComboBox* cb = (juce::ComboBox*)tbl.mc->vComponents[i].first;
								elem->setAttribute("v" + juce::String(contador++), tbl.mc->vComponents[i].first->getComponentID());
								std::string s = "0x0" + std::to_string(cb->getSelectedItemIndex());
								elem->setAttribute("v" + juce::String(contador++), s);
							}
						}

						tbl.dataList->addChildElement(elem);

						tbl.numRows++;
						if (tbl.getNumRows() > 998)
							tbl.new_button.setEnabled(false);

						tbl.modified = true;

						tbl.table.updateContent();
					}
				}
			}

			Tabla& tbl;
		};

		std::unique_ptr<juce::AlertWindow> savePresetWindow;
		struct savePresetResultChosen
		{
			void operator() (int result) const noexcept
			{
				auto& aw = *tbl.savePresetWindow;
				aw.exitModalState(result);
				aw.setVisible(false);

				if (result == 0)
				{
					return;
				}
				else if (result == 1) {
					juce::String text;
					if (aw.getTextEditorContents("Preset").isNotEmpty() &&
						aw.getTextEditorContents("Category").isNotEmpty() &&
						aw.getTextEditorContents("Autor").isNotEmpty()) {

						juce::XmlElement* node = tbl.dataList->getChildElement(tbl.selected_index);
						node->setAttribute("Preset", aw.getTextEditorContents("Preset"));
						node->setAttribute("Category", aw.getTextEditorContents("Category"));
						node->setAttribute("Autor", aw.getTextEditorContents("Autor"));
						auto option = aw.getComboBoxComponent("Rating")->getSelectedItemIndex();
						node->setAttribute("Rating", option + 1);

						int contador = 1;
						for (int i = 0; i < tbl.mc->vComponents.size(); i++) {
							if (tbl.mc->vComponents[i].second == 1) {
								juce::ToggleButton* tb = (juce::ToggleButton*)tbl.mc->vComponents[i].first;
								if (tb->getToggleState() == 1) {
									switch (tb->getName().getIntValue())
									{
									case 0:
										contador++;
										node->setAttribute("v" + juce::String(contador++), "0x00");
										break;
									case 1:
										contador++;
										node->setAttribute("v" + juce::String(contador++), "0x01");
										break;
									case 2:
										contador++;
										node->setAttribute("v" + juce::String(contador++), "0x02");
										break;
									case 3:
										contador++;
										node->setAttribute("v" + juce::String(contador++), "0x03");
										break;
									}
								}
							}
							else if (tbl.mc->vComponents[i].second == 2) {
								juce::Slider* sl = (juce::Slider*)tbl.mc->vComponents[i].first;
								int val = sl->getValue();
								val = val & 0xFF;
								std::string str = juce::String::toHexString(val).toStdString();
								std::string hex = "0x" + std::string(2 - str.size(), '0').append(str);
								contador++;
								node->setAttribute("v" + juce::String(contador++), hex);
								if (tbl.mc->vComponents[i].first->getComponentID() == "0x0D") { // Filter
									int val = sl->getValue();
									val = (val >> 8) & 0xFF;
									std::string str = juce::String::toHexString(val).toStdString();
									std::string hex = "0x" + std::string(2 - str.size(), '0').append(str);
									node->setAttribute("v" + juce::String(contador++), hex);
								}
							}
							else if (tbl.mc->vComponents[i].second == 3) {
								juce::ToggleButton* tb = (juce::ToggleButton*)tbl.mc->vComponents[i].first;
								if (tb->getToggleState()) {
									switch (tb->getButtonText().getIntValue())
									{
									case 1:
										node->setAttribute("v" + juce::String(contador++), "0x00");
										break;
									case 2:
										node->setAttribute("v" + juce::String(contador++), "0x01");
										break;
									case 3:
										node->setAttribute("v" + juce::String(contador++), "0x02");
										break;
									case 4:
										node->setAttribute("v" + juce::String(contador++), "0x03");
										break;
									}
								}
							}
							else if (tbl.mc->vComponents[i].second == 4) {
								juce::ComboBox* cb = (juce::ComboBox*)tbl.mc->vComponents[i].first;
								std::string s = "0x0" + std::to_string(cb->getSelectedItemIndex());
								contador++;
								node->setAttribute("v" + juce::String(contador++), s);
							}
						}

						tbl.modified = true;
						tbl.table.updateContent();
					}
				}
			}

			Tabla& tbl;
		};

		//==============================================================================
		// This is a custom Label component, which we use for the table's editable text columns.
		class EditableTextCustomComponent : public juce::Label
		{
		public:
			EditableTextCustomComponent(Tabla& td) : owner(td)
			{
				// double click to edit the label text; single click handled below
				//setEditable(false, true, false);
			}

			void mouseDoubleClick(const juce::MouseEvent& event) override
			{
				if (owner.last_row != row) {
					owner.mc->setXMLValues(owner.dataList, row);
					owner.last_row = row;
				}

				Label::mouseDoubleClick(event);
			}

			void mouseDown(const juce::MouseEvent& event) override
			{
				// single click on the label should simply select the row
				owner.table.selectRowsBasedOnModifierKeys(row, event.mods, false);

				owner.save_button.setEnabled(true);
				owner.selected_index = row;

				Label::mouseDown(event);
			}

			void textWasEdited() override
			{
				owner.setText(columnId, row, getText());
			}

			// Our demo code will call this when we may need to update our contents
			void setRowAndColumn(const int newRow, const int newColumn)
			{
				row = newRow;
				columnId = newColumn;
				setText(owner.getText(columnId, row), juce::dontSendNotification);
			}

			void paint(juce::Graphics& g) override
			{
				auto& lf = getLookAndFeel();
				if (!dynamic_cast<juce::LookAndFeel_V4*> (&lf))
					lf.setColour(textColourId, juce::Colours::black);

				Label::paint(g);
			}

		private:
			Tabla& owner;
			int row, columnId;
			juce::Colour textColour;
		};

		//==============================================================================
		// This is a custom component containing a combo box, which we're going to put inside
		// our table's "rating" column.
		class RatingColumnCustomComponent : public Component
		{
		public:
			RatingColumnCustomComponent(Tabla& td) : owner(td)
			{
				// just put a combo box inside this component
				addAndMakeVisible(comboBox);
				comboBox.addItem("5 stars", 1);
				comboBox.addItem("4 stars", 2);
				comboBox.addItem("3 stars", 3);
				comboBox.addItem("2 stars", 4);
				comboBox.addItem("1 stars", 5);

				comboBox.onChange = [this] { owner.setRating(row, comboBox.getSelectedId()); };
				comboBox.setWantsKeyboardFocus(false);
			}

			void resized() override
			{
				comboBox.setBoundsInset(juce::BorderSize<int>(2));
			}

			// Our demo code will call this when we may need to update our contents
			void setRowAndColumn(int newRow, int newColumn)
			{
				row = newRow;
				columnId = newColumn;
				comboBox.setSelectedId(owner.getRating(row), juce::dontSendNotification);
			}

		private:
			Tabla& owner;
			juce::ComboBox comboBox;
			int row, columnId;
		};

		//==============================================================================
		// A comparator used to sort our data when the user clicks a column header
		class DemoDataSorter
		{
		public:
			DemoDataSorter(const juce::String& attributeToSortBy, bool forwards)
				: attributeToSort(attributeToSortBy),
				direction(forwards ? 1 : -1)
			{
			}

			int compareElements(juce::XmlElement* first, juce::XmlElement* second) const
			{
				auto result = first->getStringAttribute(attributeToSort)
					.compareNatural(second->getStringAttribute(attributeToSort));

				if (result == 0)
					result = first->getStringAttribute("ID")
					.compareNatural(second->getStringAttribute("ID"));

				return direction * result;
			}

		private:
			juce::String attributeToSort;
			int direction;
		};

		juce::File getExamplesDirectory() noexcept
		{
#ifdef PIP_JUCE_EXAMPLES_DIRECTORY
			MemoryOutputStream mo;

			auto success = Base64::convertFromBase64(mo, JUCE_STRINGIFY(PIP_JUCE_EXAMPLES_DIRECTORY));
			ignoreUnused(success);
			jassert(success);

			return mo.toString();
#elif defined PIP_JUCE_EXAMPLES_DIRECTORY_STRING
			return File{ CharPointer_UTF8 { PIP_JUCE_EXAMPLES_DIRECTORY_STRING } };
#else
			auto currentFile = juce::File::getSpecialLocation(juce::File::SpecialLocationType::currentApplicationFile);
			auto exampleDir = currentFile.getParentDirectory().getChildFile("examples");

			if (exampleDir.exists())
				return exampleDir;

			// keep track of the number of parent directories so we don't go on endlessly
			for (int numTries = 0; numTries < 15; ++numTries)
			{
				if (currentFile.getFileName() == "examples")
					return currentFile;

				const auto sibling = currentFile.getSiblingFile("examples");

				if (sibling.exists())
					return sibling;

				currentFile = currentFile.getParentDirectory();
			}

			return currentFile;
#endif
		}

		std::unique_ptr<juce::InputStream> createAssetInputStream(const char* resourcePath)
		{
#if JUCE_ANDROID
			ZipFile apkZip(File::getSpecialLocation(File::invokedExecutableFile));
			return std::unique_ptr<InputStream>(apkZip.createStreamForEntry(apkZip.getIndexOfFileName("assets/" + String(resourcePath))));
#else
#if JUCE_IOS
			auto assetsDir = File::getSpecialLocation(File::currentExecutableFile)
				.getParentDirectory().getChildFile("Assets");
#elif JUCE_MAC
			auto assetsDir = File::getSpecialLocation(File::currentExecutableFile)
				.getParentDirectory().getParentDirectory().getChildFile("Resources").getChildFile("Assets");

			if (!assetsDir.exists())
				assetsDir = getExamplesDirectory().getChildFile("Assets");
#else
			auto assetsDir = getExamplesDirectory().getChildFile("Assets");
#endif

			auto resourceFile = assetsDir.getChildFile(resourcePath);
			jassert(resourceFile.existsAsFile());

			return resourceFile.createInputStream();
#endif
		}

		juce::String loadEntireAssetIntoString(const char* assetName)
		{
			std::unique_ptr<juce::InputStream> input(createAssetInputStream(assetName));

			if (input == nullptr)
				return {};

			return input->readString();
		}


		//==============================================================================
		// this loads the embedded database XML file into memory
		void loadData()
		{
			//demoData = parseXML(loadEntireAssetIntoString("demo table data.xml"));

			juce::String st = mc->audioProcessor->getCurrentExePath() + "\\presets.xml";
			demoData = parseXML(loadEntireAssetIntoString(st.toStdString().c_str()));

			dataList = demoData->getChildByName("DATA");
			columnList = demoData->getChildByName("COLUMNS");

			numRows = dataList->getNumChildElements();
		}

		// (a utility method to search our XML for the attribute that matches a column ID)
		juce::String getAttributeNameForColumnId(const int columnId) const
		{
			for (auto* columnXml : columnList->getChildIterator())
			{
				if (columnXml->getIntAttribute("columnId") == columnId)
					return columnXml->getStringAttribute("name");
			}

			return {};
		}

		JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(Tabla)
	};

private:
	juce::AudioProcessorValueTreeState& parameters;
	//juce::HashMap<juce::String, int> pvalues;

	juce::String osc1_value;
	juce::String osc2_value;
	juce::String lfo1_value;
	juce::String lfo2_value;
	juce::String lfo3_value;

	juce::GroupComponent osc1_group;
	juce::ToggleButton osc1_saw{ "SAWTOOTH" };
	juce::ToggleButton osc1_tri{ "TRIANGLE" };
	juce::ToggleButton osc1_squ{ "SQUARE" };
	juce::ToggleButton osc1_sin{ "SINE" };
	mySlider osc1_semitone;
	juce::Label osc1_semitone_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc1_semitone_attach;
	mySlider osc1_detune;
	juce::Label osc1_detune_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc1_detune_attach;
	mySlider osc1_lfo;
	juce::Label osc1_lfo_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc1_lfo_attach;
	mySlider osc1_pulse;
	juce::Label osc1_pulse_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc1_pulse_attach;
	mySlider osc1_volume;
	juce::Label osc1_volume_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc1_volume_attach;

	juce::GroupComponent osc2_group;
	juce::ToggleButton osc2_saw{ "SAWTOOTH" };
	juce::ToggleButton osc2_tri{ "TRIANGLE" };
	juce::ToggleButton osc2_squ{ "SQUARE" };
	juce::ToggleButton osc2_sin{ "SINE" };
	mySlider osc2_semitone;
	juce::Label osc2_semitone_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc2_semitone_attach;
	mySlider osc2_detune;
	juce::Label osc2_detune_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc2_detune_attach;
	mySlider osc2_lfo;
	juce::Label osc2_lfo_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc2_lfo_attach;
	mySlider osc2_pulse;
	juce::Label osc2_pulse_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc2_pulse_attach;
	mySlider osc2_volume;
	juce::Label osc2_volume_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> osc2_volume_attach;

	juce::GroupComponent amp_env_group;
	mySlider attack;
	juce::Label attack_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> attack_attach;
	mySlider attack_time;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> attack_time_attach;
	mySlider decay;
	juce::Label decay_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> decay_attach;
	mySlider decay_time;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> decay_time_attach;
	mySlider sustain;
	juce::Label sustain_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> sustain_attach;
	juce::Label sustain_time;
	mySlider release;
	juce::Label release_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> release_attach;
	mySlider release_time;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> release_time_attach;

	juce::GroupComponent lfo1_group;
	juce::ToggleButton lfo1_saw{ "SAWTOOTH" };
	juce::ToggleButton lfo1_tri{ "TRIANGLE" };
	juce::ToggleButton lfo1_squ{ "SQUARE" };
	juce::ToggleButton lfo1_sin{ "SINE" };
	mySlider lfo1_speed;
	juce::Label lfo1_speed_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> lfo1_speed_attach;
	juce::TextButton lfo1_button_left{ "1" };
	juce::TextButton lfo1_button_right{ "3" };

	juce::GroupComponent lfo2_group;
	juce::ToggleButton lfo2_saw{ "SAWTOOTH" };
	juce::ToggleButton lfo2_tri{ "TRIANGLE" };
	juce::ToggleButton lfo2_squ{ "SQUARE" };
	juce::ToggleButton lfo2_sin{ "SINE" };
	mySlider lfo2_speed;
	juce::Label lfo2_speed_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> lfo2_speed_attach;
	juce::TextButton lfo2_button_left{ "1" };
	juce::TextButton lfo2_button_right{ "3" };

	juce::GroupComponent lfo3_group;
	juce::ToggleButton lfo3_saw{ "SAWTOOTH" };
	juce::ToggleButton lfo3_tri{ "TRIANGLE" };
	juce::ToggleButton lfo3_squ{ "SQUARE" };
	juce::ToggleButton lfo3_sin{ "SINE" };
	mySlider lfo3_speed;
	juce::Label lfo3_speed_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> lfo3_speed_attach;
	juce::TextButton lfo3_button_left{ "1" };
	juce::TextButton lfo3_button_right{ "3" };
	juce::ComboBox lfo3_destination;
	std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> lfo3_destination_attach;

	juce::GroupComponent portamento_group;
	mySlider portamento;
	juce::Label portamento_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> portamento_attach;

	juce::GroupComponent master_group;
	mySlider master;
	juce::Label master_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> master_attach;

	juce::GroupComponent filter_group;
	juce::ComboBox filter_type;
	std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> filter_type_attach;
	mySlider filter_freq;
	juce::Label filter_freq_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> filter_freq_attach;
	mySlider filter_q;
	juce::Label filter_q_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> filter_q_attach;
	mySlider filter_lfo;
	juce::Label filter_lfo_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> filter_lfo_attach;
	juce::Label app_name_label;
	juce::TextButton options_button;
	juce::TextButton presets_button;

	juce::GroupComponent noise_group;
	mySlider noise_volume;
	juce::Label noise_volume_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> noise_volume_attach;
	mySlider pmod_in;
	juce::Label pmod_in_label;
	std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> pmod_in_attach;

#if STANDALONE
	std::vector<juce::juce_wchar> keyspressed;

	bool keyPressed(const juce::KeyPress& key, Component* c) override
	{
		if (!audioProcessor->connected)
			return true;

		DWORD byteswritten = 0;
		juce::juce_wchar h1_buffer;
		if (is_scale_key(key.getTextCharacter())) {
			h1_buffer = key.getTextCharacter() == 0x5A || key.getTextCharacter() == 0x7A ? 0x02 : 0x03;
			WriteFile(audioProcessor->hComm, &h1_buffer, 1, &byteswritten, NULL);
		}

		return true;
	}

	bool is_scale_key(juce::juce_wchar keypress) {
		return keypress == 0x5A || keypress == 0x7A || keypress == 0x58 || keypress == 0x78;
	}

	int byte_to_index(juce::juce_wchar keypress) { // A, W, S, E, D, F, T, G, Y, H, U, J, K, O, L
		unsigned int keypressedH[15] = { 0x41, 0x57, 0x53, 0x45, 0x44, 0x46, 0x54, 0x47, 0x59, 0x48, 0x55, 0x4A, 0x4B, 0x4F, 0x4C };
		unsigned int keypressedL[15] = { 0x61, 0x77, 0x73, 0x65, 0x64, 0x66, 0x74, 0x67, 0x79, 0x68, 0x75, 0x6A, 0x6B, 0x6F, 0x6C };
		for (int i = 0; i < 15; i++) {
			if (keypress == keypressedH[i])
				return i;
			else if (keypress == keypressedL[i])
				return i;
		}
		return 0x10;
	}

	void timerCallback() override
	{
		if (!audioProcessor->connected) return;
		juce::juce_wchar keypressedH[15] = { 0x41, 0x57, 0x53, 0x45, 0x44, 0x46, 0x54, 0x47, 0x59, 0x48, 0x55, 0x4A, 0x4B, 0x4F, 0x4C };
		juce::juce_wchar keypressedL[15] = { 0x61, 0x77, 0x73, 0x65, 0x64, 0x66, 0x74, 0x67, 0x79, 0x68, 0x75, 0x6A, 0x6B, 0x6F, 0x6C };
		for (int i = 0; i < 15; i++) {
			juce::juce_wchar key = 0x00;
			if (juce::KeyPress::isKeyCurrentlyDown(keypressedH[i]))
				key = keypressedH[i];
			else if (juce::KeyPress::isKeyCurrentlyDown(keypressedL[i]))
				key = keypressedH[i];

			if (key > 0) {
				bool send_key = true;
				for (int j = 0; j < keyspressed.size(); j++) {
					if (keyspressed[j] == key) {
						send_key = false;
						break;
					}
				}

				if (send_key) {
					keyspressed.insert(keyspressed.begin(), key);
					DWORD byteswritten = 0;
					juce::juce_wchar h1_buffer;
					int index = byte_to_index(key);
					if (index < 0x10) {
						h1_buffer = index_to_note(index);
						//printf("Sending: 0x%X\n", h1_buffer);
						WriteFile(audioProcessor->hComm, &h1_buffer, 1, &byteswritten, NULL);
					}
				}
			}
		}

		for (int i = 0; i < keyspressed.size(); i++) {
			if (!juce::KeyPress::isKeyCurrentlyDown(keyspressed[i])) {
				DWORD byteswritten = 0;
				juce::juce_wchar h1_buffer;
				h1_buffer = keyspressed[i];
				int index = byte_to_index(h1_buffer);
				if (index < 0x10) {
					unsigned char note_release = 0x04;
					WriteFile(audioProcessor->hComm, &note_release, 1, &byteswritten, NULL);
					h1_buffer = index_to_note(index);
					//printf("Sending: 0x04 0x%X\n", h1_buffer);
					WriteFile(audioProcessor->hComm, &h1_buffer, 1, &byteswritten, NULL);
				}
				//printf("key up %s", keyspressed[i]);
				keyspressed.erase(keyspressed.begin() + i);
				break;
			}
		}
	}

	unsigned char index_to_note(int index) {
		unsigned char note[15] = { 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32 };
		return note[index];
	}
#endif

	void lfoModeChanged(juce::TextButton* btn)
	{
		//if (!audioProcessor->connected) return;
		DWORD byteswritten = 0;
		int button = btn->getName().getIntValue();
		int number = (int)strtol(btn->getComponentID().toUTF8(), NULL, 0);
		juce::juce_wchar send_data = number;
		WriteFile(audioProcessor->hComm, &send_data, 1, &byteswritten, NULL);

		bool active = btn->getToggleState();
		switch (button)
		{
		case 1:
			if (!active) {
				btn->setToggleState(true, juce::dontSendNotification);
				send_data = btn->getButtonText().getIntValue() - 1;
			}
			else {
				if (btn->getButtonText() == "1") {
					btn->setButtonText("2");
					send_data = 0x01;
					audioProcessor->pvalues.set(btn->getComponentID(), 1);
				}
				else {
					btn->setButtonText("1");
					send_data = 0x00;
					audioProcessor->pvalues.set(btn->getComponentID(), 0);
				}
			}
			break;
		case 2:
			if (!active) {
				btn->setToggleState(true, juce::dontSendNotification);
				send_data = btn->getButtonText().getIntValue() - 1;
			}
			else {
				if (btn->getButtonText() == "3") {
					btn->setButtonText("4");
					send_data = 0x03;
					audioProcessor->pvalues.set(btn->getComponentID(), 3);
				}
				else {
					btn->setButtonText("3");
					send_data = 0x02;
					audioProcessor->pvalues.set(btn->getComponentID(), 2);
				}
			}
			break;
		default: break;
		}
		WriteFile(audioProcessor->hComm, &send_data, 1, &byteswritten, NULL);
	}

	void WaveTypeChanged(juce::Button* button, juce::String name)
	{
		if (!audioProcessor->connected) return;
		if ((button->getRadioGroupId() == 100 && osc1_value == name) ||
			(button->getRadioGroupId() == 200 && osc2_value == name) ||
			(button->getRadioGroupId() == 300 && lfo1_value == name) ||
			(button->getRadioGroupId() == 400 && lfo2_value == name) ||
			(button->getRadioGroupId() == 500 && lfo3_value == name))
			return;
		auto tstate = button->getToggleState();
		if (tstate == true) {
			DWORD byteswritten = 0;
			juce::juce_wchar send_data = 0x00;
			switch (button->getRadioGroupId())
			{
			case 100: // OSCILLATOR1
				osc1_value = name;
				send_data = 0x17;
				break;
			case 200: // OSCILLATOR2
				osc2_value = name;
				send_data = 0x1C;
				break;
			case 300: // LFO1
				lfo1_value = name;
				send_data = 0x11;
				break;
			case 400: // LFO2
				lfo2_value = name;
				send_data = 0x13;
				break;
			case 500: // LFO3
				lfo3_value = name;
				send_data = 0x36;
				break;
			default: break;
			}
			WriteFile(audioProcessor->hComm, &send_data, 1, &byteswritten, NULL);

			switch (name.getIntValue())
			{
			case 0: // SAWTOOOTH
				send_data = 0x00;
				break;
			case 1: // TRIANGLE
				send_data = 0x01;
				break;
			case 2: // SQUARE
				send_data = 0x02;
				break;
			case 3: // SINE
				send_data = 0x03;
				break;
			default: break;
			}
			audioProcessor->pvalues.set(button->getComponentID(), name.getIntValue());
			WriteFile(audioProcessor->hComm, &send_data, 1, &byteswritten, NULL);
		}
	}

	void setXMLValues(juce::XmlElement* dataList, int row)
	{
		for (int i = 1; i <= controls; i++) {
			bool sign = audioProcessor->state == audioProcessor->OSC1_SEMITONE || audioProcessor->state == audioProcessor->OSC2_SEMITONE ? true : false;
			int data = convertHexToInt(dataList->getChildElement(row)->getStringAttribute("v" + juce::String(i)).getHexValue32(), sign);
			audioProcessor->setParamValue(data, juce::sendNotification);
		}
	}

	int16_t convertHexToInt(int value, bool sign)
	{
		std::stringstream ss;
		int16_t val = value & 0xFF;
		ss >> val;
		return sign ? (val > 127 ? val - 256 : val) : val;
	}

	void showWindow()
	{
		asyncAlertWindow = std::make_unique<juce::AlertWindow>("FPGA_Synth Controller",
			//"Select a MIDI Input and click 'MIDI'.\nWrite down the Serial Port and click 'UART'.",
			"Write down the Serial Port and click UART button\n",
			juce::MessageBoxIconType::QuestionIcon);

		if (audioProcessor->connected)
			asyncAlertWindow->addTextBlock("FPGA Connection is ready!");
		else
			asyncAlertWindow->addTextBlock("FPGA Connection is NOT ready! Please try again");

		asyncAlertWindow->addTextEditor("com_port", audioProcessor->com_port_value, "COM Port:");
		//juce::StringArray(devices);
		//devices = updateDeviceList(devices);
		//asyncAlertWindow->addComboBox("midi_input", { devices }, "Midi Input:");

		asyncAlertWindow->addButton("UART", 1, juce::KeyPress(juce::KeyPress::returnKey, 0, 0));
		//asyncAlertWindow->addButton("MIDI", 3, juce::KeyPress(juce::KeyPress::returnKey, 0, 0));
		asyncAlertWindow->addButton("CANCEL", 0, juce::KeyPress(juce::KeyPress::escapeKey, 0, 0));
		asyncAlertWindow->addButton("ABOUT", 2, juce::KeyPress(juce::KeyPress::spaceKey, 0, 0));

		asyncAlertWindow->enterModalState(true, juce::ModalCallbackFunction::create(AsyncAlertBoxResultChosen{ *this }));
	}

	void showPresets()
	{
		if (basicWindow == nullptr) {
			juce::File file(audioProcessor->getCurrentExePath() + "\\presets.xml");

			if (file.existsAsFile())
			{
				basicWindow = new BasicWindow("Presets", juce::Colours::grey, juce::DocumentWindow::allButtons, this);
				basicWindow->setUsingNativeTitleBar(true);
				basicWindow->centreWithSize(630, 443);
				basicWindow->setVisible(true);
			}
			else
			{
				juce::AlertWindow::showAsync(juce::MessageBoxOptions()
					.withIconType(juce::MessageBoxIconType::InfoIcon)
					.withTitle("Error")
					.withMessage("Presets file is not found in path: " + file.getFullPathName())
					.withButton("OK"),
					nullptr);
			}
		}
		else
			basicWindow->toFront(true);
	}

	JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MainComponent)
};
