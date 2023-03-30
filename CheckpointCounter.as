/*
 * author: Phlarx
 */

[Setting name="Show counter"]
bool showCounter = true;

enum displays {
	Only_when_Openplanet_menu_is_open,
	Always_except_when_interface_is_hidden,
	Always
}

[Setting name="Display setting"]
displays setting_display = displays::Always_except_when_interface_is_hidden;

[Setting name="Anchor X position" min=0 max=1]
float anchorX = .5;

[Setting name="Anchor Y position" min=0 max=1]
#if TMNEXT
float anchorY = .91;
#elif TURBO
float anchorY = .895;
#elif MP4
float anchorY = .88;
#endif

[Setting name="Show background"]
bool showBackground = false;

[Setting name="Hide the counter if there are no checkpoints on the current map"]
bool hideIfZeroCP = false;

[Setting name="Font size" min=8 max=72]
int fontSize = 24;

[Setting name="Font face" description="To access a custom font, place the font file in the 'Fonts' folder\
under your Openplanet user directory (create it if it does not exist).\
Then, enter the full file name in this box."]
string fontFace = "";

[Setting name="Display mode"]
EDispMode dispMode = EDispMode::ShowCompletedAndTotal;

[Setting name="Custom display format" description="%c is completed CPs\
%d is next CP\
%r is remaining CPs\
%t is total CPs\
%C is completed laps\
%D is current lap\
%R is remaining laps\
%T is total laps\
%% is a literal %"]
string customFormat = "%c / -%r / %t";

[Setting name="Change color when go-to-finish"]
bool finishColorChange = false;

[Setting name="Change color only on last lap"]
bool finishColorChangeLastLapOnly = false;

[Setting color name="Normal color"]
vec4 colorNormal = vec4(1, 1, 1, 1);

[Setting color name="Go-to-finish color"]
vec4 colorGoToFinish = vec4(1, 0, 0, 1);

enum EDispMode {
	ShowCompletedAndTotal,
	ShowRemainingAndTotal,
	ShowCompletedAndRemaining,
	ShowCompletedAndLaps,
	ShowCompletedAndLapsOnMultilap,
	ShowLaps,
	ShowCustom
}

string curFontFace = "";
nvg::Font font;

void Main() {
	// load any custom fonts
	OnSettingsChanged();
	
	CP::Main();
}

void Update(float dt) {
	CP::Update();
}

void OnSettingsChanged() {
	if(fontFace != curFontFace) {
		font = nvg::LoadFont(fontFace, true);
		curFontFace = fontFace;
	}
}

void RenderMenu() {
	if (UI::MenuItem("\\$09f" + Icons::Flag + "\\$z Checkpoint Counter", "", showCounter)) {
		showCounter = !showCounter;
	}
}

string getDisplayText() {
	switch(dispMode) {
	case EDispMode::ShowCompletedAndTotal:
		return doFormat("%c / %t");
	case EDispMode::ShowRemainingAndTotal:
		return doFormat("-%r / %t");
	case EDispMode::ShowCompletedAndRemaining:
		return doFormat("%c / -%r");
	case EDispMode::ShowCompletedAndLaps:
		return doFormat("CP: %c / %t      Lap: %D / %T");
	case EDispMode::ShowCompletedAndLapsOnMultilap:
		if (CP::maxLap > 1) {
			return doFormat("CP: %c / %t      Lap: %D / %T");
		} else {
			return doFormat("%c / %t");
		}
		
	case EDispMode::ShowLaps:
		return doFormat("%D / %T");
	case EDispMode::ShowCustom:
		return doFormat(customFormat);
	}
	return "";
}

enum RenderMode {
    Normal,
    Interface
}

void Render() {
    if (can_render(RenderMode::Normal)) render_window();
}

void RenderInterface() {
    if (can_render(RenderMode::Interface)) render_window();
}

bool can_render(RenderMode rendermode) {
	if (!showCounter) return false;
    if (rendermode == RenderMode::Normal && (setting_display == displays::Only_when_Openplanet_menu_is_open)) return false;
    if (rendermode == RenderMode::Interface && (setting_display != displays::Only_when_Openplanet_menu_is_open)) return false;

    auto app = cast<CTrackMania>(GetApp());
#if TMNEXT||MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif
    if (map is null || map.MapInfo.MapUid == "" || app.Editor !is null) return false;
    if (app.CurrentPlayground is null || app.CurrentPlayground.Interface is null  ||
     (setting_display == displays::Always_except_when_interface_is_hidden && !UI::IsGameUIVisible())) return false;
    return true;
}

void render_window() {	
	if(CP::inGame && (CP::maxCP > 0 || !hideIfZeroCP)) {
		string text = getDisplayText();
		
		nvg::FontSize(fontSize);
		nvg::FontFace(font);
		nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
		
		vec2 size = nvg::TextBounds(text);
		
		if(showBackground) {
			nvg::FillColor(vec4(0, 0, 0, 0.8));
			nvg::BeginPath();
			nvg::RoundedRect(anchorX * Draw::GetWidth() - size.x * 0.5 - 8, anchorY * Draw::GetHeight() - size.y * 0.5 - 6, size.x + 16, size.y + 8, 5);
			nvg::Fill();
			nvg::ClosePath();
		}
		
		if(finishColorChange && CP::curCP == CP::maxCP && (!finishColorChangeLastLapOnly || CP::curLap + 1 == CP::maxLap)) {
			nvg::FillColor(colorGoToFinish);
		} else {
			nvg::FillColor(colorNormal);
		}
		
		nvg::Text(anchorX * Draw::GetWidth(), anchorY * Draw::GetHeight(), text);
	}
}

string doFormat(const string &in format) {
	string result = "";
	int idx = 0;
	while(idx < format.Length) {
		if(format[idx] == 37 /*"%"[0]*/ && idx + 1 < format.Length) {
			switch(format[idx + 1]) {
			case 67 /*"C"[0]*/:
				result += "" + CP::curLap;
				break;
			case 68 /*"D"[0]*/:
				result += "" + (CP::curLap + 1);
				break;
			case 82 /*"R"[0]*/:
				result += "" + int(CP::maxLap - CP::curLap);
				break;
			case 84 /*"T"[0]*/:
				result += "" + CP::maxLap;
				break;
			case 99 /*"c"[0]*/:
				result += "" + CP::curCP;
				break;
			case 100 /*"d"[0]*/:
				result += "" + (CP::curCP + 1);
				break;
			case 114 /*"r"[0]*/:
				result += "" + int(CP::maxCP - CP::curCP);
				break;
			case 116 /*"t"[0]*/:
				result += "" + CP::maxCP;
				break;
			case 37 /*"%"[0]*/:
				result += "%";
				break;
			default:
				result += format.SubStr(idx, 2);
				break;
			}
			idx += 2;
		} else {
			result += format.SubStr(idx, 1);
			idx += 1;
		}
	}
	return result;
}
