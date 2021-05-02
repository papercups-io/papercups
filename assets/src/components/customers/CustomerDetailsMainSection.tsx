import React from 'react';
import {History} from 'history';
import {Box} from 'theme-ui';
import qs from 'query-string';
import {Tabs} from '../common';
import CustomerDetailsCard from './CustomerDetailsCard';
import CustomerDetailsConversations from './CustomerDetailsConversations';
import CustomerDetailsNotes from './CustomerDetailsNotes';
import CustomerDetailsIssues from './CustomerDetailsIssues';

const {TabPane} = Tabs;

enum TabKey {
  Conversations = 'Conversations',
  Notes = 'Notes',
  Issues = 'Issues',
}

const getDefaultTab = (query: string): TabKey => {
  const {tab = 'conversations'} = qs.parse(query);

  switch (tab) {
    case 'notes':
      return TabKey.Notes;
    case 'issues':
      return TabKey.Issues;
    case 'conversations':
    default:
      return TabKey.Conversations;
  }
};

type Props = {customerId: string; history: History};

const CustomerDetailsMainSection = ({customerId, history}: Props) => {
  const defaultActiveKey = getDefaultTab(history.location.search);

  return (
    <CustomerDetailsCard>
      <Box>
        <Tabs
          defaultActiveKey={defaultActiveKey}
          tabBarStyle={{paddingLeft: '16px', marginBottom: '0'}}
        >
          <TabPane tab={TabKey.Conversations} key={TabKey.Conversations}>
            <CustomerDetailsConversations
              customerId={customerId}
              history={history}
            />
          </TabPane>
          <TabPane tab={TabKey.Notes} key={TabKey.Notes}>
            <CustomerDetailsNotes customerId={customerId} />
          </TabPane>
          <TabPane tab={TabKey.Issues} key={TabKey.Issues}>
            <CustomerDetailsIssues customerId={customerId} />
          </TabPane>
        </Tabs>
      </Box>
    </CustomerDetailsCard>
  );
};

export default CustomerDetailsMainSection;
