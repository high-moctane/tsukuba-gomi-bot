package main

import "time"

var JapaneseWeekDay = map[string]string{
	"Mon": "月",
	"Tue": "火",
	"Wed": "水",
	"Thu": "木",
	"Fri": "金",
	"Sat": "土",
	"Sun": "日",
}

func dateFormat(date time.Time) string {
	return date.Format("1月2日（") + JapaneseWeekDay[date.Format("Mon")] + "）"
}

func timeFormat(t time.Time) string {
	return t.Format("15:04")
}

func loadJST() (jst *time.Location, err error) {
	jst, err = time.LoadLocation("Asia/Tokyo")
	if err != nil {
		return
	}
	return
}

func TodayMessage(c Calendar) (string, error) {
	jst, err := loadJST()
	if err != nil {
		return "", err
	}
	today := time.Now().In(jst)
	ans := "今日" + dateFormat(today) + "のごみは\n"
	ans += c.Date(today) + "\n"
	ans += "です(｀･ω･´) " + timeFormat(time.Now())
	return ans, nil
}

func TomorrowMessage(c Calendar) (string, error) {
	jst, err := loadJST()
	if err != nil {
		return "", err
	}
	tomorrow := time.Now().In(jst).Add(24 * time.Hour)
	ans := "明日" + dateFormat(tomorrow) + "のごみは\n"
	ans += c.Date(tomorrow) + "\n"
	ans += "です(｀･ω･´) " + timeFormat(time.Now())
	return ans, err
}
