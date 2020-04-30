package main

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

type Entry struct {
	Date     string `json:"date"`
	District string `json:"district"`
	Garbage  string `json:"garbage"`
}

type Entries []Entry

func (ent *Entries) ToCalendar() Calendar {
	cal := make(Calendar)
	for _, e := range *ent {
		if cal[e.Date] == nil {
			cal[e.Date] = make(map[string]string)
		}
		cal[e.Date][e.District] = e.Garbage
	}
	return cal
}

// カレンダー全部を読み込む
func ReadEntries(sourceDir string) (Entries, error) {
	files, err := ioutil.ReadDir(sourceDir)
	if err != nil {
		return nil, err
	}

	ans := Entries{}

	for _, f := range files {
		ent := Entries{}

		pth := filepath.Join(sourceDir, f.Name())
		f, err := os.Open(pth)
		if err != nil {
			return nil, err
		}
		defer f.Close()

		dec := json.NewDecoder(f)
		if err := dec.Decode(&ent); err == io.EOF {
			continue
		} else if err != nil {
			return nil, err
		}
		ans = append(ans, ent...)
	}
	return ans, nil
}

// map["2019-07-01"]map["東地区"]ごみ名
type Calendar map[string]map[string]string

func NewCalendar(sourceDir string) (Calendar, error) {
	ent, err := ReadEntries(sourceDir)
	if err != nil {
		return nil, err
	}
	return ent.ToCalendar(), nil
}

// 日付からその日のごみカレンダー string を返す
func (c *Calendar) Date(date time.Time) string {
	strans := []string{}
	datestr := date.Format("2006-01-02")
	for district, garbage := range (*c)[datestr] {
		strans = append(strans, district+"："+garbage)
	}
	sort.Strings(strans)
	return strings.Join(strans, "\n")
}
