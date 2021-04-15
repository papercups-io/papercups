import React from 'react';

import {Box} from 'theme-ui';
import {Tabs} from '../common';
import CustomerDetailsCard from './CustomerDetailsCard';
import CustomerDetailsConversations from './CustomerDetailsConversations';

const {TabPane} = Tabs;

enum TAB_KEYS {
  Conversations = 'Conversations',
  Notes = 'Notes',
}

type Props = {customerId: string};
type State = {};

class CustomerDetailsPrimarySection extends React.Component<Props, State> {
  render() {
    return (
      <CustomerDetailsCard>
        <Box>
          <Tabs
            defaultActiveKey={TAB_KEYS.Conversations}
            size="large"
            tabBarStyle={{paddingLeft: '16px', marginBottom: '0'}}
          >
            <TabPane tab={TAB_KEYS.Conversations} key={TAB_KEYS.Conversations}>
              <CustomerDetailsConversations
                customerId={this.props.customerId}
              />
            </TabPane>
            <TabPane tab={TAB_KEYS.Notes} key={TAB_KEYS.Notes}>
              Notes
            </TabPane>
          </Tabs>
        </Box>
      </CustomerDetailsCard>
    );
  }
}

export default CustomerDetailsPrimarySection;
