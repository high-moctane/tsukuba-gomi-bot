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
	return t.Format("03:04")
}

func TodayMessage(c Calendar) string {
	today := time.Now()
	ans := "今日" + dateFormat(today) + "のごみは\n"
	ans += c.Date(today) + "\n"
	ans += "です(｀･ω･´) " + timeFormat(time.Now())
	return ans
}

func TomorrowMessage(c Calendar) string {
	tomorrow := time.Now().Add(24 * time.Hour)
	ans := "明日" + dateFormat(tomorrow) + "のごみは\n"
	ans += c.Date(tomorrow) + "\n"
	ans += "です(｀･ω･´) " + timeFormat(time.Now())
	return ans
}
