import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Text, Tooltip} from '../common';
import * as API from '../../api';
import {Issue} from '../../types';
import logger from '../../logger';
import {IssueStateTag} from '../issues/IssuesTable';
import {NewIssueModalButton} from '../issues/NewIssueModal';
import Spinner from '../Spinner';
import useChannel from './useChannel';

const SidebarCustomerIssues = ({customerId}: {customerId: string}) => {
  const [loading, setLoading] = React.useState(false);
  const [customerIssues, setCustomerIssues] = React.useState<Array<Issue>>([]);

  useChannel(`issue:lobby:${customerId}`, {
    handlers: {
      'issue:created': () => refreshCustomerIssues(),
      'issue:updated': () => refreshCustomerIssues(),
    },
  });

  React.useEffect(() => {
    setLoading(true);

    API.fetchAllIssues({customer_id: customerId})
      .then((issues: Array<Issue>) => setCustomerIssues(issues))
      .catch((err) => logger.error('Error retrieving customer issues:', err))
      .finally(() => setLoading(false));
  }, [customerId]);

  async function refreshCustomerIssues() {
    API.fetchAllIssues({customer_id: customerId})
      .then((issues: Array<Issue>) => setCustomerIssues(issues))
      .catch((err) => logger.error('Error retrieving customer issues:', err));
  }

  if (loading) {
    return <Spinner size={16} />;
  }

  return (
    <Box>
      {customerIssues.length === 0 && (
        <Box mb={1}>
          <Text type="secondary">None</Text>
        </Box>
      )}
      {customerIssues.length > 0 && (
        <Box pb={2} mb={2} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
          {customerIssues
            .sort((a: Issue, b: Issue) => {
              return +new Date(b.updated_at) - +new Date(a.updated_at);
            })
            .map((issue) => {
              const {id, title, state} = issue;

              return (
                <Link key={id} to={`/issues/${id}`}>
                  <Tooltip title={title} placement="left">
                    <Flex mb={2}>
                      <IssueStateTag state={state} />

                      <Text
                        style={{
                          whiteSpace: 'nowrap',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                        }}
                      >
                        {title}
                      </Text>
                    </Flex>
                  </Tooltip>
                </Link>
              );
            })}
        </Box>
      )}

      <Box>
        <NewIssueModalButton
          type="default"
          size="small"
          customerId={customerId}
          onSuccess={refreshCustomerIssues}
        >
          Add
        </NewIssueModalButton>
      </Box>
    </Box>
  );
};

export default SidebarCustomerIssues;
