package gomibot

import "testing"

func TestGarbageString(t *testing.T) {
	if Garbage(NoCollecting).String() != "収集なし" {
		t.Error("wrong naming")
	}
}

func TestNoCollecting(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"収集なし", true},
		{"燃やせない", false},
		{"かん", false},
		{"粗大ごみ", false},
		{"ペットボトル", false},
		{"びん", false},
		{"スプレー缶", false},
		{"紙", false},
		{"布", false},
		{"燃やせる", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsNoCollecting(test.input); ans != test.expected {
			t.Errorf("IsNoCollecting(%q) = %v", test.input, ans)
		}
	}
}

func TestIsBurnableGarbage(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"燃やせる", true},
		{"もやせる", true},
		{"燃やす", true},
		{"もやす", true},
		{"燃える", true},
		{"萌える", true},
		{"もえる", true},
		{"燃やせない", false},
		{"もやせない", false},
		{"燃やさない", false},
		{"もやさない", false},
		{"燃えない", false},
		{"萌えない", false},
		{"もえない", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsBurnableGarbage(test.input); ans != test.expected {
			t.Errorf("IsBurnableGarbage(%q) = %v", test.input, ans)
		}
	}
}

func TestIsUsedPaperAndClothes(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"紙", true},
		{"かみ", true},
		{"こし", true},
		{"布", true},
		{"こふ", true},
		{"ぬの", true},
		{"燃やせる", false},
		{"燃えない", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsUsedPaperAndClothes(test.input); ans != test.expected {
			t.Errorf("IsUsedPaperAndClothes(%q) = %v", test.input, ans)
		}
	}
}

func TestIsGlassBottlesAndSplayCans(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"びん", true},
		{"ビン", true},
		{"瓶", true},
		{"スプレー缶", true},
		{"すぷれー缶", true},
		{"紙", false},
		{"布", false},
		{"燃やせる", false},
		{"燃えない", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsGlassBottlesAndSplayCans(test.input); ans != test.expected {
			t.Errorf("IsGlassBottlesAndSplayCans(%q) = %v", test.input, ans)
		}
	}
}

func TestPlasticBottles(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"ペットボトル", true},
		{"ペット", true},
		{"ぺっと", true},
		{"びん", false},
		{"スプレー缶", false},
		{"紙", false},
		{"布", false},
		{"燃やせる", false},
		{"燃えない", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsPlasticBottles(test.input); ans != test.expected {
			t.Errorf("IsPlasticBottles(%q) = %v", test.input, ans)
		}
	}
}

func TestOversizedGarbage(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"粗大ごみ", true},
		{"そだいごみ", true},
		{"粗大", true},
		{"そだい", true},
		{"ペットボトル", false},
		{"びん", false},
		{"スプレー缶", false},
		{"紙", false},
		{"布", false},
		{"燃やせる", false},
		{"燃えない", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsOversizedGarbage(test.input); ans != test.expected {
			t.Errorf("IsOversizedGarbage(%q) = %v", test.input, ans)
		}
	}
}

func TestCans(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"かん", true},
		{"缶", true},
		{"カン", true},
		{"粗大ごみ", false},
		{"ペットボトル", false},
		{"びん", false},
		{"スプレー缶", false},
		{"紙", false},
		{"布", false},
		{"燃やせる", false},
		{"燃えない", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsCans(test.input); ans != test.expected {
			t.Errorf("IsCans(%q) = %v", test.input, ans)
		}
	}
}

func TestNonBurnableGarbage(t *testing.T) {
	tests := []struct {
		input    string
		expected bool
	}{
		{"燃やせない", true},
		{"もやせない", true},
		{"燃やさない", true},
		{"もやさない", true},
		{"燃えない", true},
		{"萌えない", true},
		{"もえない", true},
		{"かん", false},
		{"粗大ごみ", false},
		{"ペットボトル", false},
		{"びん", false},
		{"スプレー缶", false},
		{"紙", false},
		{"布", false},
		{"燃やせる", false},
		{"", false},
		{"ぜんぜん違う文字列", false},
	}

	for _, test := range tests {
		if ans := IsNonBurnableGarbage(test.input); ans != test.expected {
			t.Errorf("IsNonBurnableGarbage(%q) = %v", test.input, ans)
		}
	}
}

func TestParseGarbage(t *testing.T) {
	tests := []struct {
		input    string
		expected Garbage
	}{
		{"収集なし", NoCollecting},
		{"燃やせるごみ", BurnableGarbage},
		{"紙", UsedPaperAndClothes},
		{"びん", GlassBottlesAndSplayCans},
		{"ペットボトル", PlasticBottles},
		{"粗大ごみ", OversizedGarbage},
		{"かん", Cans},
		{"燃やせないごみ", NonBurnableGarbage},
	}

	for _, test := range tests {
		g, err := ParseGarbage(test.input)
		if err != nil {
			t.Errorf("%q is a sanity string", test.input)
		}
		if g != test.expected {
			t.Errorf("%q is not %s",
				test.input, Garbage(test.expected).String())
		}
	}

	// error check
	_, err := ParseGarbage("")
	if err == nil {
		t.Errorf("\"\" causes no error")
	}
}
