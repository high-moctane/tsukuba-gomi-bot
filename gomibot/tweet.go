package main

import (
	"log"
	"time"

	"github.com/dghubble/go-twitter/twitter"
)

func RegularTweet(client *twitter.Client, c Calendar) error {
	var mes string
	if time.Now().Hour() < 12 {
		mes = TodayMessage(c)
	} else {
		mes = TomorrowMessage(c)
	}
	if _, _, err := client.Statuses.Update(mes, nil); err != nil {
		return err
	}
	return nil
}

// TODO: そのうち時間指定できたりとかにする
func RegularTweetServer(client *twitter.Client, c Calendar) {
	for {
		time.Sleep(1.5 * time.Hour)
		if err := RegularTweet(client, c); err != nil {
			log.Println("regular tweet error:", err)
		}
		time.Sleep(1.5 * time.Hour)
	}
}
