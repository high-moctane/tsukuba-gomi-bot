package gomibot

import (
	"sort"
	"testing"
	"time"
)

func TestNewDay(t *testing.T) {
	tests := []struct {
		date, garbage string
		day           Day
		e             error
	}{
		{
			"2017-09-01",
			"燃やせるごみ",
			Day{
				time.Date(2017, 9, 1, 0, 0, 0, 0, location),
				BurnableGarbage,
			},
			nil,
		},
	}

	for _, test := range tests {
		d, err := NewDay(test.date, test.garbage)
		if err != test.e {
			t.Errorf("(%q, %s) => (%s, %v)",
				test.date, test.garbage, d, err)
		}
		if test.day.String() != d.String() {
			t.Errorf("(%q, %s) => (%s, %v)",
				test.date, test.garbage, d, err)
		}
	}
}

func TestCalSort(t *testing.T) {
	tests := []struct {
		input, expected Calendar
	}{
		{
			Calendar{},
			Calendar{},
		},
		{
			Calendar{
				{
					time.Date(2017, 1, 2, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 2, 10, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2018, 10, 21, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 2, 11, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2018, 10, 20, 0, 0, 0, 0, location),
					NoCollecting,
				},
			},
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 1, 2, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 2, 10, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 2, 11, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2018, 10, 20, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2018, 10, 21, 0, 0, 0, 0, location),
					NoCollecting,
				},
			},
		},
	}

	for _, test := range tests {
		sort.Sort(test.input)
		if test.input.String() != test.expected.String() {
			t.Errorf("expected %q, but %q",
				test.expected.String(), test.input.String())
		}
	}
}

func TestCalString(t *testing.T) {
	tests := []struct {
		input    Calendar
		expected string
	}{
		{
			Calendar{},
			"",
		},
		{
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
			},
			"2017-01-01: 収集なし",
		},
		{
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 1, 2, 0, 0, 0, 0, location),
					BurnableGarbage,
				},
			},
			"2017-01-01: 収集なし\n2017-01-02: 燃やせるごみ",
		},
	}

	for _, test := range tests {
		ans := test.input.String()
		if ans != test.expected {
			t.Errorf("expected %q, but %q", test.expected, ans)
		}
	}
}

func TestCalParse(t *testing.T) {
	tests := []struct {
		input    string
		expected Calendar
	}{
		{
			"",
			Calendar{},
		},
		{
			"2017-01-01: 収集なし",
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
			},
		},
		{
			"2017-01-01: 収集なし\n2017-01-02: 燃やせるごみ",
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 1, 2, 0, 0, 0, 0, location),
					BurnableGarbage,
				},
			},
		},
		{
			"2017-01-02: 燃やせるごみ\n2017-01-01: 収集なし",
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 1, 2, 0, 0, 0, 0, location),
					BurnableGarbage,
				},
			},
		},
		{
			"#data\n2017-01-02: 燃やせるごみ\n\n2017-01-01: 収集なし",
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2017, 1, 2, 0, 0, 0, 0, location),
					BurnableGarbage,
				},
			},
		},
	}

	for i, test := range tests {
		ans, err := CalParse(test.input)
		if err != nil {
			t.Error(i, ": ", err)
		}
		if !ans.Equal(test.expected) {
			t.Errorf("expected %q, but %q",
				test.expected.String(), ans.String())
		}
	}
}

func TestParseAppend(t *testing.T) {
	tests := []struct {
		input    string
		expected Calendar
	}{
		{
			"",
			Calendar{
				{
					time.Date(2018, 12, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
			},
		},
		{
			"2017-01-01: 収集なし",
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2018, 12, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
			},
		},
		{
			"2017-01-01: 収集なし\n2019-01-02: 燃やせるごみ",
			Calendar{
				{
					time.Date(2017, 1, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2018, 12, 1, 0, 0, 0, 0, location),
					NoCollecting,
				},
				{
					time.Date(2019, 1, 2, 0, 0, 0, 0, location),
					BurnableGarbage,
				},
			},
		},
	}

	for _, test := range tests {
		cal := Calendar{
			{
				time.Date(2018, 12, 1, 0, 0, 0, 0, location),
				NoCollecting,
			},
		}
		if err := cal.ParseAppend(test.input); err != nil {
			t.Error(err)
		}
		if !cal.Equal(test.expected) {
			t.Errorf("expected %q, but %q",
				test.expected.String(), cal.String())
		}
	}

}
