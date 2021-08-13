var createElement = (label, options = null) => {
    let newElement = document.createElement(label)
    if (options != null) {
        if (options.hasOwnProperty('classes')) {
            for (let newClass of options.classes) {
                newElement.classList.add(newClass)
            }
        }
        if (options.hasOwnProperty('backgroundColor')) {
            newElement.style.backgroundColor = `#${options.backgroundColor}`
        }
        if (options.hasOwnProperty('text')) {
            newElement.textContent = options.text
        }
        if (options.hasOwnProperty('activity')) {
            newElement.activity = options.activity
        }
        if (options.hasOwnProperty('minHeight')) {
            newElement.style.minHeight = `#${options.minHeight}px`
        }
        if (options.hasOwnProperty('maxHeight')) {
            newElement.style.maxHeight = `#${options.maxHeight}px`
        }
        if (options.hasOwnProperty('type')) {
            newElement.type = options.type
        }
        if (options.hasOwnProperty('defaultValue')) {
            newElement.defaultValue = options.defaultValue
        }
        if (options.hasOwnProperty('onClick')) {
            newElement.addEventListener('click', options.onClick)
        }
        if (options.hasOwnProperty('src')) {
            newElement.src = options.src
        }
        if (options.hasOwnProperty('draggable')) {
            newElement.setAttribute('draggable', options.draggable)
        }
        if (options.hasOwnProperty('name')) {
            newElement.setAttribute('name', options.name)
        }
        if (options.hasOwnProperty('value')) {
            newElement.setAttribute('value', options.value)
        }
        if (options.hasOwnProperty('checked')) {
            newElement.setAttribute('checked', options.checked)
        }
        if (options.hasOwnProperty('onChange')) {
            newElement.addEventListener('change', options.onChange)
        }
        if (options.hasOwnProperty('shouldExpand')) {
            newElement.shouldExpand = options.shouldExpand
        }
    }
    return newElement
} 

var findAncestor = (element, query) => {
    return element.closest(query)
}

var findPanelItem = (element) => {
    return findAncestor(element, '.panel-item')
}

var findChildIndex = (element, parent = null) => {
    if (parent == null) {
        return Array.from(element.parentNode.children).indexOf(element);
    } else {
        return Array.from(parent.children).indexOf(element);
    }
}