package gomibot

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/pkg/errors"
)

const (
	locationName  = "Asia/Tokyo"
	dateStrLayout = "2006-01-02"
)

var location *time.Location

func init() {
	loadLocation()
}

// loadLocation sets timezone
func loadLocation() {
	var err error
	location, err = time.LoadLocation(locationName)
	if err != nil {
		panic("LoadLocation error")
	}
}

// NewDay creates Day struct.
func NewDay(date, garbage string) (Day, error) {
	d, err := time.ParseInLocation(dateStrLayout, date, location)
	if err != nil {
		return Day{}, errors.Wrap(err, "date parse error")
	}
	g, err := ParseGarbage(garbage)
	if err != nil {
		return Day{}, errors.Wrap(err, "garbage parse error")
	}
	return Day{Date: d, Garbage: g}, nil
}

// Day is a property of one day.
type Day struct {
	Date    time.Time
	Garbage Garbage
}

func (d *Day) String() string {
	if d == nil {
		return "nil"
	}
	return d.Date.Format("2006-01-02") + ": " +
		Garbage(d.Garbage).String()
}

// Equal reports whether d and other is the same.
func (d Day) Equal(other Day) bool {
	return d.Date.Equal(other.Date) && d.Garbage == other.Garbage
}

// Calendar is a slice of Day(s)
type Calendar []Day

// Len returns the calendar's length.
func (c Calendar) Len() int {
	return len(c)
}

// Less reports whether the element with
// index i should sort before the element with index j.
func (c Calendar) Less(i, j int) bool {
	return c[i].Date.Before(c[j].Date)
}

// Swap swaps the elements with index i and j.
func (c Calendar) Swap(i, j int) {
	c[i], c[j] = c[j], c[i]
}

// Equal reports whether c and other is the same.
func (c Calendar) Equal(other Calendar) bool {
	for i := range c {
		if !c[i].Equal(other[i]) {
			return false
		}
	}
	return true
}

func (c Calendar) String() string {
	sli := make([]string, 0, len(c))
	for _, d := range c {
		sli = append(sli, d.String())
	}
	return strings.Join(sli, "\n")
}

// CalParse reads s and returns Calendar.
func CalParse(s string) (Calendar, error) {
	sli := strings.Split(s, "\n")
	ans := make(Calendar, 0, len(sli))
	for i, line := range sli {
		if len(line) == 0 || strings.HasPrefix(line, "#") {
			continue
		}
		elem := strings.Split(line, ": ")
		if len(elem) != 2 {
			return nil, CalendarParseError{line: i}
		}
		day, err := NewDay(elem[0], elem[1])
		if err != nil {
			return nil, CalendarParseError{line: i}
		}
		ans = append(ans, day)
	}
	sort.Sort(ans)
	return ans, nil
}

// CalendarParseError occurs when (Calendar).Parse failed.
type CalendarParseError struct {
	line int
}

func (e CalendarParseError) Error() string {
	return fmt.Sprintf("line %d: invalid input", e.line)
}

// ParseAppend reads s and append days into c.
func (c *Calendar) ParseAppend(s string) error {
	cal, err := CalParse(s)
	if err != nil {
		return errors.Wrap(err, "ParseAppend error")
	}
	*c = append(*c, cal...)
	sort.Sort(*c)
	return nil
}

func (c Calendar) Dump(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return errors.Wrap(err, "dump error")
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	defer w.Flush()
	if _, err := w.WriteString(c.String() + "\n"); err != nil {
		return errors.Wrap(err, "dump error")
	}
	return nil
}
