import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors} from './common';
import {DownOutlined, UpOutlined} from './icons';
import Widget from './Widget';

type Props = {};
type State = {
  open: boolean;
};

class EmbeddableWidget extends React.Component<Props, State> {
  state: State = {open: false};

  componentDidMount() {
    // Load widget
  }

  handleToggleOpen = () => {
    this.setState({open: !this.state.open});
  };

  render() {
    const {open} = this.state;

    return (
      <>
        {/* TODO: use emotion or styled to handle this? */}
        {open && (
          <Box
            style={{
              zIndex: 2147483000,
              position: 'fixed',
              bottom: '100px',
              right: '20px',
              width: '376px',
              minHeight: '250px',
              maxHeight: '704px',
              boxShadow: 'rgba(0, 0, 0, 0.16) 0px 5px 40px',
              opacity: 1,
              height: 'calc(100% - 120px)',
              borderRadius: 8,
              overflow: 'hidden',
            }}
          >
            <Widget />
          </Box>
        )}
        <Box
          style={{
            color: colors.white,
            background: colors.primary,
            position: 'fixed',
            zIndex: 2147483003,
            bottom: '20px',
            right: '20px',
            width: '60px',
            height: '60px',
            borderRadius: '50%',
            cursor: 'pointer',
            boxShadow:
              '0 1px 6px 0 rgba(0, 0, 0, 0.06), 0 2px 32px 0 rgba(0, 0, 0, 0.16)',
          }}
        >
          <Flex
            sx={{
              justifyContent: 'center',
              alignItems: 'center',
              height: '100%',
              width: '100%',
            }}
            // TODO: don't use onClick handler here?
            onClick={this.handleToggleOpen}
          >
            {open ? (
              <DownOutlined style={{fontSize: 16}} />
            ) : (
              <UpOutlined style={{fontSize: 16}} />
            )}
          </Flex>
        </Box>
      </>
    );
  }
}

export default EmbeddableWidget;
