package main

import (
	"log"
	"time"

	"github.com/dghubble/go-twitter/twitter"
)

func RegularTweet(client *twitter.Client, c Calendar) error {
	var mes string
	var err error
	if time.Now().Hour() < 12 {
		mes, err = TodayMessage(c)
		if err != nil {
			return err
		}
	} else {
		mes, err = TomorrowMessage(c)
		if err != nil {
			return err
		}
	}
	if _, _, err := client.Statuses.Update(mes, nil); err != nil {
		return err
	}
	return nil
}

// TODO: そのうち時間指定できたりとかにする
func RegularTweetServer(client *twitter.Client, c Calendar) {
	for {
		time.Sleep(1*time.Hour + 30*time.Minute)
		if err := RegularTweet(client, c); err != nil {
			log.Println("regular tweet error:", err)
		}
		time.Sleep(1*time.Hour + 30*time.Minute)
	}
}
