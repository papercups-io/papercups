import React from 'react';
import {History} from 'history';
import {Box} from 'theme-ui';
import {Tabs} from '../common';
import CustomerDetailsCard from './CustomerDetailsCard';
import CustomerDetailsConversations from './CustomerDetailsConversations';
import CustomerDetailsNotes from './CustomerDetailsNotes';

const {TabPane} = Tabs;

enum TAB_KEYS {
  Conversations = 'Conversations',
  Notes = 'Notes',
}

type Props = {customerId: string; history: History};

const CustomerDetailsMainSection = ({customerId, history}: Props) => {
  return (
    <CustomerDetailsCard>
      <Box>
        <Tabs
          defaultActiveKey={TAB_KEYS.Conversations}
          tabBarStyle={{paddingLeft: '16px', marginBottom: '0'}}
        >
          <TabPane tab={TAB_KEYS.Conversations} key={TAB_KEYS.Conversations}>
            <CustomerDetailsConversations
              customerId={customerId}
              history={history}
            />
          </TabPane>
          <TabPane tab={TAB_KEYS.Notes} key={TAB_KEYS.Notes}>
            <CustomerDetailsNotes customerId={customerId} />
          </TabPane>
        </Tabs>
      </Box>
    </CustomerDetailsCard>
  );
};

export default CustomerDetailsMainSection;
