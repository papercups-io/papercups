import React, {useEffect, useRef} from 'react';
import rrwebPlayer from 'rrweb-player';
import {eventWithTime} from 'rrweb/typings/types';
import 'rrweb-player/dist/style.css';

export default function RrWebPlayer({events}: {events: eventWithTime[]}) {
  const target = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (target.current) {
      new rrwebPlayer({
        target: target.current,
        // eslint-disable-next-line
        // @ts-ignore
        props: {
          width: 900,
          events,
          autoPlay: true,
        },
      });
    }
  }, []);

  return <div ref={target} id="rrweb-player"></div>;
}
