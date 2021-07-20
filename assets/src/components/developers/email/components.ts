export const JS_COMPONENTS = `

const Paragraph = (props) => {
  const {children, align = 'left'} = props;

  return (
    <p className={\`papercups-align-\${align}\`} align={align}>
      {children}
    </p>
  )
};

const H2 = (props) => {
  const {children, align = 'left'} = props;

  return (
    <h2 className={\`papercups-align-\${align}\`} align={align}>
      {children}
    </h2>
  )
};

const Body = (props) => {
  return (
    <td
      class="comment_body_td content-td"
      style={{
        '-webkit-background-clip': 'padding-box',
        '-webkit-border-radius': '0 0 3px 3px',
        'background-clip': 'padding-box',
        'background-color': 'white',
        'border-radius': '0 0 3px 3px',
        color: '#525252',
        'font-family': "'Helvetica Neue',Arial,sans-serif",
        'font-size': '15px',
        'line-height': '22px',
        overflow: 'hidden',
        padding: '40px 40px 30px',
      }}
      bgcolor="white"
    >
      {props.children}
    </td>
  );
};

const Content = (props) => {
  const {children, bordered = false, theme = {}} = props;

  return (
    <table
      cellpadding="0"
      cellspacing="0"
      border="0"
      class="comment_wrapper_table admin_comment"
      align="center"
      style={{
        '-webkit-background-clip': 'padding-box',
        '-webkit-border-radius': '3px',
        'background-clip': 'padding-box',
        'border-collapse': 'collapse',
        'border-radius': '3px',
        color: '#545454',
        'font-family': "'Helvetica Neue',Arial,sans-serif",
        'font-size': '13px',
        'line-height': '20px',
        margin: '0 auto',
        width: '100%',
      }}
    >
      <tbody>
        <tr>
          <td valign="top" class="comment_wrapper_td">
            {/* Top border */}
            {/* TODO: when to show/hide this table? */}
            {bordered && (
              <table
                cellpadding="0"
                cellspacing="0"
                border="0"
                class="comment_header"
                style={{
                  border: 'none',
                  'border-collapse': 'separate',
                  'font-size': '1px',
                  height: '2px',
                  'line-height': '3px',
                  width: '100%',
                }}
              >
                <tbody>
                  <tr>
                    <td
                      valign="top"
                      class="comment_header_td"
                      style={{
                        'background-color': theme.color || 'rgb(155, 48, 247)',
                        border: 'none',
                        'font-family': "'Helvetica Neue',Arial,sans-serif",
                        width: '100%',
                      }}
                      bgcolor={theme.color || "rgb(155, 48, 247)"}
                    >
                      &nbsp;
                    </td>
                  </tr>
                </tbody>
              </table>
            )}

            {/* Message body wrapper */}
            <table
              cellpadding="0"
              cellspacing="0"
              border="0"
              class="comment_body"
              // style="-webkit-background-clip: padding-box; background-clip: padding-box; border-bottom-style: none; border-collapse: collapse; width: 100%"
              style={{
                'background-clip': 'padding-box',
                'border-collapse': 'collapse',
                width: '100%',
                ...(bordered
                  ? {
                      'border-color': '#dddddd',
                      'border-radius': '0 0 3px 3px',
                      // 'border-style': 'solid solid none',
                      'border-style': 'solid solid',
                      'border-width': '0 1px 1px',
                    }
                  : {}),
              }}
            >
              <tbody>
                <tr>
                  {children}
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

const MessageFooterSection = () => {
  return (
    <table
      cellpadding="0"
      cellspacing="0"
      border="0"
      class="message_footer_table"
      align="center"
      // style="border-collapse: collapse; color: #545454; font-family: 'Helvetica Neue',Arial,sans-serif; font-size: 13px; line-height: 20px; margin: 0 auto; max-width: 100%; width: 100%"
    >
      <tbody>
        <tr>&nbsp;</tr>
      </tbody>
    </table>
  );
};

const UnsubscribeSection = (props) => {
  return (
    <table width="100%" cellpadding="0" cellspacing="0" border="0">
      <tbody>
        <tr>
          <td width="25%" class="footer-td-wrapper">
            <table
              width="100%"
              cellpadding="0"
              cellspacing="0"
              border="0"
              style={{
                'border-collapse': 'collapse',
                color: '#545454',
                'font-family': "'Helvetica Neue',Arial,sans-serif",
                'font-size': '13px',
                'line-height': '20px',
                margin: '0 auto',
                'max-width': '100%',
                width: '100%',
              }}
              class="message_footer_table"
            >
              <tbody>
                <tr>
                  <td
                    valign="middle"
                    align="center"
                    class="date_cell"
                    style={{
                      color: '#999999',
                      'font-size': '11px',
                      'text-align': 'center',
                    }}
                  >
                    <a
                      href={props.unsubscribeLinkUrl}
                      style={{color: '#999999'}}
                    >
                      Unsubscribe from our emails
                    </a>
                  </td>
                </tr>
                <tr>&nbsp;</tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

const Container = (props) => {
  return (
    <table
      style={{
        'border-collapse': 'collapse',
        margin: 'auto',
        maxWidth: props.maxWidth || '635px',
        minWidth: props.minWidth || '320px',
        width: '100%',
      }}
      class="main-wrap"
    >
      <tbody>
        <tr>
          <td valign="top">
            <table
              cellpadding="0"
              cellspacing="0"
              border="0"
              class="reply_header_table"
              style={{
                'border-collapse': 'collapse',
                color: '#c0c0c0',
                'font-family': "'Helvetica Neue',Arial,sans-serif",
                'font-size': '13px',
                'line-height': '26px',
                margin: '0 auto 26px',
                width: '100%',
              }}
            ></table>
          </td>
        </tr>

        <tr>
          <td valign="top" class="main_wrapper" style={{padding: '0 20px'}}>
            {props.children}

            <MessageFooterSection />
            <UnsubscribeSection />
          </td>
        </tr>
      </tbody>
    </table>
  );
};

const Layout = (props) => {
  return (
    <table
      cellpadding="0"
      cellspacing="0"
      border="0"
      class="bgtc personal"
      align="center"
      bgcolor={props.background || '#f9f9f9'}
      style={{
        'background-color': props.background || '#f9f9f9',
        'border-collapse': 'collapse',
        'line-height': '100%',
        // margin: '0px',
        // padding: '0px',
        width: '100%',
      }}
    >
      <tbody>
        <tr>
          <td>
            {/* TODO: figure out how to make this work */}
            {props.children}
          </td>
        </tr>
      </tbody>
    </table>
  );
};
`;
