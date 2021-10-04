import React from 'react';
import {Link} from 'react-router-dom';
import {Button} from '../common';
import {VideoCameraOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';

export const CustomerActiveSessions = ({customerId}: {customerId: string}) => {
  const [loading, setLoading] = React.useState(false);
  const [session, setLiveSession] = React.useState<any>();

  React.useEffect(() => {
    setLoading(true);

    API.fetchBrowserSessions({customerId, isActive: true, limit: 5})
      .then(([session]) => setLiveSession(session))
      .catch((err) => logger.error('Error retrieving sessions:', err))
      .then(() => setLoading(false));
  }, [customerId]);

  const sessionId = session && session.id;

  return (
    <Link to={sessionId ? `/sessions/live/${sessionId}` : '/sessions'}>
      <Button
        type="primary"
        icon={<VideoCameraOutlined />}
        block
        ghost
        loading={loading}
      >
        View live
      </Button>
    </Link>
  );
};

export default CustomerActiveSessions;
