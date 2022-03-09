import React from 'react';
import ReactDOM from 'react-dom';
import './index.styl';

class Main extends React.Component {
    constructor() {
        super()
    }

    render() {
        return (
            <div>
                <Sidebar />
            </div>
        )
    }
}

// Create the basic sidebar html, then we'll add the style css
// This is the sidebar where you take all your actions
class sidebar extends React.Component {
    constructor() {
        super()
        this.state = {
            showLimitOrderInput: false
        }
    }

    render() {
        return (
            <div className='sidebar'>
                <div className='selected-assets-title'>Selected assets:</div>
                <div className='selected-asset-one'>ETH</div>
                <div className='selected-asset-two'>BTC</div>
                <div className='your-portfolio'>Your Portfolio:</div>
                <div className='grid-center'>ETH:</div><div className='grid-name'>10</div>
                <div className='grid-center'>BTC:</div><div className='grid-name'>200</div>
                <div className='money-management'>Money management:</div>
                <button className='button-outline'>Deposit</button>
                <button className='button-outline'>Withdraw</button>
                <div className='actions'>Actions:</div>
                <button className='buy'>Buy</button>
                <button className='sell'>Sell</button>
                <select defaultValue='market-order' onChange = {selected => {if(selected.target.value == 'limit-order')this.setState({showLimitOrderInput: true})
                                    else this.setState({showLimitOrderInput: false})}}>
                                        <option value='market-order'>Market Order</option>
                                        <option value='limit-order'>Limit Order</option>
                </select>
                <input ref='limit-order-amount' className={this.state.showLimitOrderInput ? '' : 'hidden'} type='number' placeholder='Price to buy or sell at...'/>
            </div>
        )
    }
}