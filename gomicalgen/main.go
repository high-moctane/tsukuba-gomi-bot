package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

func main() {
	dstdir, err := Dstdir()
	if err != nil {
		log.Fatal(err)
	}

	filename, date, err := GetFilenameDate()
	if err != nil {
		log.Fatal(err)
	}

	cal, err := MakeCalendar(filename, date)
	if err != nil {
		log.Fatal(err)
	}

	json, err := cal.Dump()
	if err != nil {
		log.Fatal(err)
	}

	if err := SaveJson(dstdir, filename, json); err != nil {
		log.Fatal(err)
	}

	fmt.Println("セーブしました")
}

func Dstdir() (string, error) {
	if len(os.Args) < 2 {
		return "", fmt.Errorf("usage: ./gomicalgen dstdir")
	}

	dstdir := os.Args[1]

	fi, err := os.Stat(dstdir)
	if err != nil {
		return "", err
	}

	if !fi.IsDir() {
		return "", fmt.Errorf("no such directory: %s", dstdir)
	}

	return dstdir, nil
}

func GetFilenameDate() (string, time.Time, error) {
	var yearmonth string
	fmt.Println("年-月を入力してください")
	fmt.Println("例: 2006-01")
	fmt.Print("> ")
	if _, err := fmt.Scan(&yearmonth); err != nil {
		return "", time.Now(), err
	}
	date, err := time.Parse("2006-01", yearmonth)
	if err != nil {
		fmt.Println("日付のフォーマットが不正です")
		return "", time.Now(), fmt.Errorf("illegal format: %s", yearmonth)
	}

	var district string
	fmt.Println("地区を入力してください")
	fmt.Println("例: north")
	fmt.Print("> ")
	if _, err := fmt.Scan(&district); err != nil {
		return "", time.Now(), err
	}
	if !(district == "north" || district == "south" || district == "west" || district == "east") {
		fmt.Println("地区は north, south, west, east のいずれかにしてください")
		return "", time.Now(), fmt.Errorf("illegal district: %s", district)
	}

	return yearmonth + "_" + district + ".json", date, nil
}

func MakeCalendar(filename string, startDate time.Time) (Calendar, error) {
	cal := Calendar{}
	date := startDate
	for date.Month() == startDate.Month() {
		fmt.Println(`コマンド: "n" 次の日, 整数 ごみの種類`)
		for i := 0; i < len(Garbages); i++ {
			fmt.Printf("[%d] %s\n", i, Garbages[i])
		}
		fmt.Println("日付:", date.Format("2006-01-02"))
		fmt.Print("> ")

		var cmd string
		if _, err := fmt.Scan(&cmd); err != nil {
			return nil, err
		}
		if cmd == "n" {
			date = date.Add(24*time.Hour + 10*time.Minute) // なんかうるう秒とかあったら嫌なので
			continue
		}
		cmdint, err := strconv.ParseInt(cmd, 10, 64)
		if err != nil || cmdint < 0 || len(Garbages) <= int(cmdint) {
			fmt.Println("不正な入力です: ", cmd)
			continue
		}
		cal.Add(date, Garbages[cmdint])
	}
	return cal, nil
}

func SaveJson(dstdir, filename string, json []byte) error {
	path := filepath.Join(dstdir, filename)
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.Write(json)
	if err != nil {
		return err
	}

	return nil
}
