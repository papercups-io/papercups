import React from 'react';
import {History} from 'history';
import {Box} from 'theme-ui';
import {Tabs} from '../common';
import CustomerDetailsCard from './CustomerDetailsCard';
import CustomerDetailsConversations from './CustomerDetailsConversations';
import CustomerDetailsNotes from './CustomerDetailsNotes';
import CustomerDetailsIssues from './CustomerDetailsIssues';

const {TabPane} = Tabs;

enum TabKeys {
  Conversations = 'Conversations',
  Notes = 'Notes',
  Issues = 'Issues',
}

type Props = {customerId: string; history: History};

const CustomerDetailsMainSection = ({customerId, history}: Props) => {
  return (
    <CustomerDetailsCard>
      <Box>
        <Tabs
          defaultActiveKey={TabKeys.Conversations}
          tabBarStyle={{paddingLeft: '16px', marginBottom: '0'}}
        >
          <TabPane tab={TabKeys.Conversations} key={TabKeys.Conversations}>
            <CustomerDetailsConversations
              customerId={customerId}
              history={history}
            />
          </TabPane>
          <TabPane tab={TabKeys.Notes} key={TabKeys.Notes}>
            <CustomerDetailsNotes customerId={customerId} />
          </TabPane>
          <TabPane tab={TabKeys.Issues} key={TabKeys.Issues}>
            <CustomerDetailsIssues customerId={customerId} />
          </TabPane>
        </Tabs>
      </Box>
    </CustomerDetailsCard>
  );
};

export default CustomerDetailsMainSection;
