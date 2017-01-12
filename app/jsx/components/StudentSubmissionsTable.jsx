define([
  'react',
  'plugins/analytics/react-bootstrap-table',
  'i18n!analytics'
], function (React, ReactBootstrapTable, I18n) {

  const { BootstrapTable, TableHeaderColumn } = ReactBootstrapTable;

  const tableOptions = {
    sizePerPage: 30,
    sizePerPageList: []
  };

  return React.createClass({
    displayName: 'StudentSubmissionsTable',

    propTypes: {
      data: React.PropTypes.object.isRequired
    },

    formatStyle (styles = {}) {
      styles.fontWeight = 'bold';
      return function (cell, row) {
        return <span style={styles}>{cell}</span>;
      };
    },

    formatDate (cell, row) {
      if (!cell) return I18n.t('N/A');
      return I18n.l('date.formats.default', cell);
    },

    render () {
      return (
        <div>
          <BootstrapTable data={this.props.data} pagination={true} options={tableOptions}>
            <TableHeaderColumn dataField='title' isKey={true}>{I18n.t('Assignment Name')}</TableHeaderColumn>
            <TableHeaderColumn dataField='status'>{I18n.t('Status')}</TableHeaderColumn>
            <TableHeaderColumn dataField='dueAt' dataFormat={this.formatDate}>{I18n.t('Due At')}</TableHeaderColumn>
            <TableHeaderColumn dataField='submittedAt' dataFormat={this.formatDate}>{I18n.t('Submitted At')}</TableHeaderColumn>
            <TableHeaderColumn dataField='score'>{I18n.t('Score')}</TableHeaderColumn>
          </BootstrapTable>
        </div>

      );
    }
  });
});

