import React from 'react';

export const Variable = (props) => {
  if (props.value) {
    return props.value;
  } else if (props.template) {
    // TODO: is there a way to do this without the <span>?
    // TODO: add data attributes so we can figure out which variables are required?
    return <span dangerouslySetInnerHTML={{__html: props.template}}></span>;
  } else {
    return props.default;
  }
};

export const Paragraph = (props) => {
  const {children, align = 'left'} = props;

  return (
    <p className={`papercups-align-${align}`} align={align}>
      {children}
    </p>
  );
};

export const H2 = (props) => {
  const {children, align = 'left'} = props;

  return (
    <h2 className={`papercups-align-${align}`} align={align}>
      {children}
    </h2>
  );
};

export const Body = (props) => {
  return (
    <td
      className="comment_body_td content-td"
      style={{
        WebkitBackgroundClip: 'padding-box',

        WebkitBorderRadius: '0 0 3px 3px',
        backgroundClip: 'padding-box',
        backgroundColor: 'white',
        borderRadius: '0 0 3px 3px',
        color: '#525252',
        fontFamily: "'Helvetica Neue',Arial,sans-serif",
        fontSize: '15px',
        lineHeight: '22px',
        overflow: 'hidden',
        padding: '40px 40px 30px',
      }}
      bgcolor="white"
    >
      {props.children}
    </td>
  );
};

export const Content = (props) => {
  const {children, bordered = false, theme = {}} = props;

  return (
    <table
      cellPadding="0"
      cellSpacing="0"
      border="0"
      className="comment_wrapper_table admin_comment"
      align="center"
      style={{
        WebkitBackgroundClip: 'padding-box',
        WebkitBorderRadius: '3px',
        backgroundClip: 'padding-box',
        borderCollapse: 'collapse',
        borderRadius: '3px',
        color: '#545454',
        fontFamily: "'Helvetica Neue',Arial,sans-serif",
        fontSize: '13px',
        lineHeight: '20px',
        margin: '0 auto',
        width: '100%',
      }}
    >
      <tbody>
        <tr>
          <td valign="top" className="comment_wrapper_td">
            {/* Top border */}
            {/* TODO: when to show/hide this table? */}
            {bordered && (
              <table
                cellPadding="0"
                cellSpacing="0"
                border="0"
                className="comment_header"
                style={{
                  border: 'none',
                  borderCollapse: 'separate',
                  fontSize: '1px',
                  height: '2px',
                  lineHeight: '3px',
                  width: '100%',
                }}
              >
                <tbody>
                  <tr>
                    <td
                      valign="top"
                      className="comment_header_td"
                      style={{
                        backgroundColor: theme.color || 'rgb(155, 48, 247)',
                        border: 'none',
                        fontFamily: "'Helvetica Neue',Arial,sans-serif",
                        width: '100%',
                      }}
                      bgcolor={theme.color || 'rgb(155, 48, 247)'}
                    >
                      &nbsp;
                    </td>
                  </tr>
                </tbody>
              </table>
            )}

            {/* Message body wrapper */}
            <table
              cellPadding="0"
              cellSpacing="0"
              border="0"
              className="comment_body"
              // style="-webkit-background-clip: padding-box; background-clip: padding-box; border-bottom-style: none; border-collapse: collapse; width: 100%"
              style={{
                backgroundClip: 'padding-box',
                borderCollapse: 'collapse',
                width: '100%',
                ...(bordered
                  ? {
                      borderColor: '#dddddd',
                      borderRadius: '0 0 3px 3px',
                      // borderStyle: 'solid solid none',
                      borderStyle: 'solid solid',
                      borderWidth: '0 1px 1px',
                    }
                  : {}),
              }}
            >
              <tbody>
                <tr>{children}</tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

export const MessageFooterSection = () => {
  return (
    <table
      cellPadding="0"
      cellSpacing="0"
      border="0"
      className="message_footer_table"
      align="center"
      // style="border-collapse: collapse; color: #545454; font-family: 'Helvetica Neue',Arial,sans-serif; font-size: 13px; line-height: 20px; margin: 0 auto; max-width: 100%; width: 100%"
    >
      <tbody>
        <tr>&nbsp;</tr>
      </tbody>
    </table>
  );
};

export const UnsubscribeSection = (props) => {
  return (
    <table width="100%" cellPadding="0" cellSpacing="0" border="0">
      <tbody>
        <tr>
          <td width="25%" className="footer-td-wrapper">
            <table
              width="100%"
              cellPadding="0"
              cellSpacing="0"
              border="0"
              style={{
                borderCollapse: 'collapse',
                color: '#545454',
                fontFamily: "'Helvetica Neue',Arial,sans-serif",
                fontSize: '13px',
                lineHeight: '20px',
                margin: '0 auto',
                maxWidth: '100%',
                width: '100%',
              }}
              className="message_footer_table"
            >
              <tbody>
                <tr>
                  <td
                    valign="middle"
                    align="center"
                    className="date_cell"
                    style={{
                      color: '#999999',
                      fontSize: '11px',
                      textAlign: 'center',
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

export const Container = (props) => {
  return (
    <table
      style={{
        borderCollapse: 'collapse',
        margin: 'auto',
        maxWidth: props.maxWidth || '635px',
        minWidth: props.minWidth || '320px',
        width: '100%',
      }}
      className="main-wrap"
    >
      <tbody>
        <tr>
          <td valign="top">
            <table
              cellPadding="0"
              cellSpacing="0"
              border="0"
              className="reply_header_table"
              style={{
                borderCollapse: 'collapse',
                color: '#c0c0c0',
                fontFamily: "'Helvetica Neue',Arial,sans-serif",
                fontSize: '13px',
                lineHeight: '26px',
                margin: '0 auto 26px',
                width: '100%',
              }}
            ></table>
          </td>
        </tr>

        <tr>
          <td valign="top" className="main_wrapper" style={{padding: '0 20px'}}>
            {props.children}

            <MessageFooterSection />
            <UnsubscribeSection />
          </td>
        </tr>
      </tbody>
    </table>
  );
};

export const Layout = (props) => {
  return (
    <table
      cellPadding="0"
      cellSpacing="0"
      border="0"
      className="bgtc personal"
      align="center"
      bgcolor={props.background || '#f9f9f9'}
      style={{
        backgroundColor: props.background || '#f9f9f9',
        borderCollapse: 'collapse',
        lineHeight: '100%',
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
