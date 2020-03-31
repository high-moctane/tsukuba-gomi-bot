package main

import (
	"encoding/json"
	"time"
)

var Districts = []string{"北地区", "西地区A", "西地区B", "東地区", "南地区"}

var Garbages = []string{
	"収集なし",
	"燃やせるごみ",
	"燃やせないごみ",
	"プラ製容器包装，粗大ごみ（予約制）",
	"古紙・古布",
	"びん，スプレー容器",
	"ペットボトル",
	"かん",
}

type Entry struct {
	Date     string `json:"date"`
	District string `json:"district"`
	Garbage  string `json:"garbage"`
}

type Calendar []Entry

func (c *Calendar) Add(date time.Time, district, garbage string) {
	if c == nil {
		cal := make(Calendar, 0)
		c = &cal
	}
	datestr := date.Format("2006-01-02")
	*c = append(*c, Entry{datestr, district, garbage})
}

func (c *Calendar) Dump() ([]byte, error) {
	json, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return []byte{}, err
	}
	return json, nil
}
